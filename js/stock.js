
// ------------------------------------------------------------
// Historique des mouvements de stock (audit — qui a fait quoi)
// ------------------------------------------------------------
async function getMouvementsStockRecents(limit = 20) {
  const { data, error } = await supabaseClient
    .from("mouvements_stock")
    .select("*, produits(nom), utilisateurs(nom)")
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data;
}

// ------------------------------------------------------------
// Correction rapide du stock (+1/-1), pour les petits ajustements
// ------------------------------------------------------------
async function corrigerStock(produitId, delta, utilisateurId) {
  const { data: produit, error: e1 } = await supabaseClient
    .from("produits")
    .select("stock")
    .eq("id", produitId)
    .single();
  if (e1) throw e1;

  const nouveauStock = Math.max(0, produit.stock + delta);
  const { error: e2 } = await supabaseClient.from("produits").update({ stock: nouveauStock }).eq("id", produitId);
  if (e2) throw e2;

  const { error: e3 } = await supabaseClient.from("mouvements_stock").insert({
    produit_id: produitId,
    type: delta > 0 ? "livraison" : "vente",
    quantite: delta,
    created_by: utilisateurId,
  });
  if (e3) throw e3;

  return nouveauStock;
}

// ------------------------------------------------------------
// Modifier un produit existant (prix, nom, prix variable)
// ------------------------------------------------------------
async function modifierProduit(produitId, updates) {
  const { data, error } = await supabaseClient
    .from("produits")
    .update(updates)
    .eq("id", produitId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function ajouterProduit({ secteurId, nom, categorie, prixVente, emplacement, prixVariable }) {
  const { data, error } = await supabaseClient
    .from("produits")
    .insert({
      secteur_id: secteurId,
      nom,
      categorie,
      prix_vente: prixVente || 0,
      emplacement: emplacement || null,
      prix_variable: prixVariable || false,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

// ------------------------------------------------------------
// Livraison — augmente directement le stock (un seul niveau,
// plus de grenier/frigo séparés)
// ------------------------------------------------------------
async function enregistrerLivraison(produitId, quantite, utilisateurId) {
  const { error: e1 } = await supabaseClient
    .from("mouvements_stock")
    .insert({ produit_id: produitId, type: "livraison", quantite, created_by: utilisateurId });
  if (e1) throw e1;

  const { data: produit, error: e2 } = await supabaseClient
    .from("produits")
    .select("stock")
    .eq("id", produitId)
    .single();
  if (e2) throw e2;

  const { error: e3 } = await supabaseClient
    .from("produits")
    .update({ stock: produit.stock + quantite })
    .eq("id", produitId);
  if (e3) throw e3;
}

// ------------------------------------------------------------
// Valorisation du stock — valeur des livraisons vs valeur des
// ventes réelles, par produit, pour un mois donné
// ------------------------------------------------------------
async function getValorisationDuMois(anneeMois) {
  const debut = anneeMois + "-01";
  const finDate = new Date(anneeMois + "-01");
  finDate.setMonth(finDate.getMonth() + 1);
  const fin = finDate.toISOString().slice(0, 10);

  const { data: livraisons, error: e1 } = await supabaseClient
    .from("mouvements_stock")
    .select("produit_id, quantite, produits(nom, prix_vente, emplacement)")
    .eq("type", "livraison")
    .gte("date", debut)
    .lt("date", fin);
  if (e1) throw e1;

  const { data: ventes, error: e2 } = await supabaseClient
    .from("mouvements_caisse")
    .select("produit_id, montant")
    .eq("type", "vente")
    .eq("categorie", "boisson")
    .gte("created_at", debut)
    .lt("created_at", fin);
  if (e2) throw e2;

  const parProduit = {};
  livraisons.forEach(l => {
    if (!l.produits) return;
    const id = l.produit_id;
    if (!parProduit[id]) parProduit[id] = { nom: l.produits.nom, emplacement: l.produits.emplacement, valeurLivree: 0, valeurVendue: 0 };
    parProduit[id].valeurLivree += l.quantite * l.produits.prix_vente;
  });
  ventes.forEach(v => {
    if (!v.produit_id || !parProduit[v.produit_id]) return;
    parProduit[v.produit_id].valeurVendue += v.montant;
  });

  return Object.values(parProduit);
}
