
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
// Correction rapide du stock frigo (+1/-1), pour les petits
// ajustements sans passer par le formulaire de livraison
// ------------------------------------------------------------
async function corrigerStockFrigo(produitId, delta, utilisateurId) {
  const { data: produit, error: e1 } = await supabaseClient
    .from("produits")
    .select("stock_frigo")
    .eq("id", produitId)
    .single();
  if (e1) throw e1;

  const nouveauStock = Math.max(0, produit.stock_frigo + delta);
  const { error: e2 } = await supabaseClient.from("produits").update({ stock_frigo: nouveauStock }).eq("id", produitId);
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
// Stock — livraisons & transferts grenier -> frigo
// ------------------------------------------------------------
async function enregistrerLivraison(produitId, quantite, utilisateurId) {
  const { error: e1 } = await supabaseClient
    .from("mouvements_stock")
    .insert({ produit_id: produitId, type: "livraison", quantite, created_by: utilisateurId });
  if (e1) throw e1;

  const { data: produit, error: e2 } = await supabaseClient
    .from("produits")
    .select("stock_grenier")
    .eq("id", produitId)
    .single();
  if (e2) throw e2;

  const { error: e3 } = await supabaseClient
    .from("produits")
    .update({ stock_grenier: produit.stock_grenier + quantite })
    .eq("id", produitId);
  if (e3) throw e3;
}

async function transfererVersFrigo(produitId, quantite, utilisateurId) {
  const { data: produit, error: e1 } = await supabaseClient
    .from("produits")
    .select("stock_grenier, stock_frigo")
    .eq("id", produitId)
    .single();
  if (e1) throw e1;

  if (produit.stock_grenier < quantite) {
    throw new Error("Pas assez de stock au grenier.");
  }

  const { error: e2 } = await supabaseClient
    .from("produits")
    .update({
      stock_grenier: produit.stock_grenier - quantite,
      stock_frigo: produit.stock_frigo + quantite,
    })
    .eq("id", produitId);
  if (e2) throw e2;

  const { error: e3 } = await supabaseClient
    .from("mouvements_stock")
    .insert({ produit_id: produitId, type: "grenier_vers_frigo", quantite, created_by: utilisateurId });
  if (e3) throw e3;
}
