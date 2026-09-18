
// ------------------------------------------------------------
// Ajouter un nouveau produit au catalogue
// ------------------------------------------------------------
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
