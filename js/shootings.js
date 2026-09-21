
// ------------------------------------------------------------
// Shootings photo — 3 prix possibles, comme la piscine
// ------------------------------------------------------------
const PRIX_SHOOTING = [2500, 5000, 10000];

async function getVentesShootingDuJour() {
  const aujourdhui = new Date().toISOString().slice(0, 10);
  const { data, error } = await supabaseClient
    .from("ventes_shooting")
    .select("*")
    .eq("date", aujourdhui);
  if (error) throw error;
  return data;
}

async function ajouterVenteShooting(prixUnitaire, caisseId, utilisateurId) {
  const { data, error } = await supabaseClient
    .from("ventes_shooting")
    .insert({ prix_unitaire: prixUnitaire, caisse_id: caisseId, created_by: utilisateurId })
    .select()
    .single();
  if (error) throw error;

  const { error: e2 } = await supabaseClient.from("mouvements_caisse").insert({
    caisse_id: caisseId,
    type: "vente",
    montant: prixUnitaire,
    description: "Shooting photo (" + prixUnitaire.toLocaleString("fr-FR") + " FCFA)",
    created_by: utilisateurId,
  });
  if (e2) throw e2;

  return data;
}

async function annulerVenteShooting(prixUnitaire, caisseId) {
  const aujourdhui = new Date().toISOString().slice(0, 10);

  const { data: derniere, error: e1 } = await supabaseClient
    .from("ventes_shooting")
    .select("*")
    .eq("date", aujourdhui)
    .eq("prix_unitaire", prixUnitaire)
    .eq("caisse_id", caisseId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (e1) throw e1;
  if (!derniere) return false;

  const { error: e2 } = await supabaseClient.from("ventes_shooting").delete().eq("id", derniere.id);
  if (e2) throw e2;

  const { data: dernierMouvement, error: e3 } = await supabaseClient
    .from("mouvements_caisse")
    .select("id")
    .eq("caisse_id", caisseId)
    .eq("type", "vente")
    .eq("montant", prixUnitaire)
    .ilike("description", "Shooting photo%")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (e3) throw e3;
  if (dernierMouvement) {
    await supabaseClient.from("mouvements_caisse").delete().eq("id", dernierMouvement.id);
  }

  return true;
}
