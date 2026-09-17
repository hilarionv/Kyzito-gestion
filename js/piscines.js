
// ------------------------------------------------------------
// Piscines — tickets journaliers, prix unitaire fixe
// ------------------------------------------------------------
const PRIX_TICKET_PISCINE = 3000;

async function getVentesPiscineDuJour() {
  const aujourdhui = new Date().toISOString().slice(0, 10);
  const { data, error } = await supabaseClient
    .from("ventes_piscine")
    .select("*")
    .eq("date", aujourdhui);
  if (error) throw error;
  return data;
}

async function ajouterTicketsPiscine(nombreTickets, caisseId, utilisateurId) {
  const { data, error } = await supabaseClient
    .from("ventes_piscine")
    .insert({
      nombre_tickets: nombreTickets,
      prix_unitaire: PRIX_TICKET_PISCINE,
      caisse_id: caisseId,
      created_by: utilisateurId,
    })
    .select()
    .single();
  if (error) throw error;

  const { error: e2 } = await supabaseClient.from("mouvements_caisse").insert({
    caisse_id: caisseId,
    type: "vente",
    montant: nombreTickets * PRIX_TICKET_PISCINE,
    description: nombreTickets + " ticket(s) piscine",
    created_by: utilisateurId,
  });
  if (e2) throw e2;

  return data;
}
