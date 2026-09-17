
// ------------------------------------------------------------
// Dépenses partagées mensuelles (multi-secteurs)
// ------------------------------------------------------------
async function creerDepensePartagee({ mois, annee, type, montant, description, secteurIds }) {
  const { data: depense, error: e1 } = await supabaseClient
    .from("depenses_partagees")
    .insert({ mois, annee, type, montant, description })
    .select()
    .single();
  if (e1) throw e1;

  const lignes = secteurIds.map(secteurId => ({ depense_id: depense.id, secteur_id: secteurId }));
  const { error: e2 } = await supabaseClient.from("depenses_partagees_secteurs").insert(lignes);
  if (e2) throw e2;

  return depense;
}

async function getDepensesPartageesDuMois(mois, annee) {
  const { data, error } = await supabaseClient
    .from("depenses_partagees")
    .select("*, depenses_partagees_secteurs(secteurs(nom))")
    .eq("mois", mois)
    .eq("annee", annee)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}
