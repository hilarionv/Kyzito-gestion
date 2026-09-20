
// ------------------------------------------------------------
// Piscines — tickets journaliers, 5 prix possibles
// ------------------------------------------------------------
const PRIX_TICKETS_PISCINE = [2000, 2500, 3000, 4000, 5000];

async function getVentesPiscineDuJour() {
  const aujourdhui = new Date().toISOString().slice(0, 10);
  const { data, error } = await supabaseClient
    .from("ventes_piscine")
    .select("*")
    .eq("date", aujourdhui);
  if (error) throw error;
  return data;
}

async function ajouterTicketPiscine(prixUnitaire, caisseId, utilisateurId) {
  const { data, error } = await supabaseClient
    .from("ventes_piscine")
    .insert({
      nombre_tickets: 1,
      prix_unitaire: prixUnitaire,
      caisse_id: caisseId,
      created_by: utilisateurId,
    })
    .select()
    .single();
  if (error) throw error;

  const { error: e2 } = await supabaseClient.from("mouvements_caisse").insert({
    caisse_id: caisseId,
    type: "vente",
    montant: prixUnitaire,
    description: "Ticket piscine (" + prixUnitaire.toLocaleString("fr-FR") + " FCFA)",
    created_by: utilisateurId,
  });
  if (e2) throw e2;

  return data;
}
