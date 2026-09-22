
// ------------------------------------------------------------
// Chambres
// ------------------------------------------------------------
async function getTypesChambres() {
  const { data, error } = await supabaseClient.from("types_chambres").select("*").order("prix_nuit");
  if (error) throw error;
  return data;
}

async function getChambres() {
  const { data, error } = await supabaseClient
    .from("chambres")
    .select("*, types_chambres(nom, prix_nuit)")
    .order("numero");
  if (error) throw error;
  return data;
}

async function getReservationsDuJour() {
  const aujourdhui = new Date().toISOString().slice(0, 10);
  const { data, error } = await supabaseClient
    .from("reservations_chambres")
    .select("*, chambres(numero, types_chambres(nom))")
    .lte("date_debut", aujourdhui)
    .gte("date_fin", aujourdhui)
    .neq("statut", "annulee");
  if (error) throw error;
  return data;
}

async function getReservationsAVenir() {
  const aujourdhui = new Date().toISOString().slice(0, 10);
  const { data, error } = await supabaseClient
    .from("reservations_chambres")
    .select("*, chambres(numero, types_chambres(nom))")
    .gt("date_debut", aujourdhui)
    .neq("statut", "annulee")
    .order("date_debut", { ascending: true });
  if (error) throw error;
  return data;
}

async function getReservationsPassees(limit = 30) {
  const aujourdhui = new Date().toISOString().slice(0, 10);
  const { data, error } = await supabaseClient
    .from("reservations_chambres")
    .select("*, chambres(numero, types_chambres(nom))")
    .lt("date_fin", aujourdhui)
    .order("date_fin", { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data;
}

async function creerReservation({ chambreId, clientNom, dateDebut, dateFin, montantTotal, caisseId }) {
  const { data, error } = await supabaseClient
    .from("reservations_chambres")
    .insert({
      chambre_id: chambreId,
      client_nom: clientNom,
      date_debut: dateDebut,
      date_fin: dateFin,
      montant_total: montantTotal,
      statut: "reservee",
      caisse_id: caisseId,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function marquerOccupee(reservationId) {
  const { error } = await supabaseClient
    .from("reservations_chambres")
    .update({ statut: "occupee" })
    .eq("id", reservationId);
  if (error) throw error;
}

// Enregistre le paiement d'une réservation comme une vente sur la caisse hôtel.
async function encaisserReservation(reservation, caisseId, utilisateurId) {
  const { error } = await supabaseClient.from("mouvements_caisse").insert({
    caisse_id: caisseId,
    type: "vente",
    montant: reservation.montant_total,
    description: "Chambre " + reservation.chambres.numero + " — " + reservation.client_nom,
    created_by: utilisateurId,
  });
  if (error) throw error;
}
