
// ------------------------------------------------------------
// Salle de conférence — tarif fixe 100 000 FCFA / jour
// ------------------------------------------------------------
const TARIF_SALLE = 100000;

async function getReservationsSalleDuMois() {
  const debut = new Date();
  debut.setDate(1);
  const { data, error } = await supabaseClient
    .from("reservations_salle")
    .select("*")
    .gte("date", debut.toISOString().slice(0, 10))
    .order("date", { ascending: false });
  if (error) throw error;
  return data;
}

async function reserverSalle(date, clientNom, caisseId, utilisateurId) {
  const { data, error } = await supabaseClient
    .from("reservations_salle")
    .insert({ date, client_nom: clientNom, montant: TARIF_SALLE, statut: "reservee", caisse_id: caisseId })
    .select()
    .single();
  if (error) throw error;

  const { error: e2 } = await supabaseClient.from("mouvements_caisse").insert({
    caisse_id: caisseId,
    type: "vente",
    montant: TARIF_SALLE,
    description: "Salle de conférence — " + clientNom,
    created_by: utilisateurId,
  });
  if (e2) throw e2;

  return data;
}
