
// ------------------------------------------------------------
// Shootings photo — 3 paliers de prix fixes
// ------------------------------------------------------------
const PRIX_SHOOTING = [2500, 5000, 10000];

async function getReservationsShootingDuMois() {
  const debut = new Date();
  debut.setDate(1);
  const { data, error } = await supabaseClient
    .from("reservations_shooting")
    .select("*")
    .gte("date", debut.toISOString().slice(0, 10))
    .order("date", { ascending: false });
  if (error) throw error;
  return data;
}

async function reserverShooting(date, clientNom, prix, caisseId, utilisateurId) {
  const { data, error } = await supabaseClient
    .from("reservations_shooting")
    .insert({ date, client_nom: clientNom, prix, statut: "reservee", caisse_id: caisseId, created_by: utilisateurId })
    .select()
    .single();
  if (error) throw error;

  const { error: e2 } = await supabaseClient.from("mouvements_caisse").insert({
    caisse_id: caisseId,
    type: "vente",
    montant: prix,
    description: "Shooting photo — " + clientNom,
    created_by: utilisateurId,
  });
  if (e2) throw e2;

  return data;
}
