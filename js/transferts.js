
// ------------------------------------------------------------
// Transferts inter-caisses
// ------------------------------------------------------------
async function getCaissesAvecSecteur() {
  const { data, error } = await supabaseClient
    .from("caisses")
    .select("*, secteurs(nom)")
    .order("nom");
  if (error) throw error;
  return data;
}

async function creerTransfert({ caisseSourceId, caisseDestId, montant, motif, utilisateurId }) {
  // 1. mouvement sortant côté source
  const { data: sortant, error: e1 } = await supabaseClient
    .from("mouvements_caisse")
    .insert({
      caisse_id: caisseSourceId,
      type: "transfert_sortant",
      montant,
      description: motif,
      created_by: utilisateurId,
    })
    .select()
    .single();
  if (e1) throw e1;

  // 2. mouvement entrant côté destination
  const { data: entrant, error: e2 } = await supabaseClient
    .from("mouvements_caisse")
    .insert({
      caisse_id: caisseDestId,
      type: "transfert_entrant",
      montant,
      description: motif,
      created_by: utilisateurId,
    })
    .select()
    .single();
  if (e2) throw e2;

  // 3. le transfert lui-même, qui relie les deux mouvements
  const { data, error: e3 } = await supabaseClient
    .from("transferts")
    .insert({
      caisse_source_id: caisseSourceId,
      caisse_dest_id: caisseDestId,
      montant,
      motif,
      mouvement_sortant_id: sortant.id,
      mouvement_entrant_id: entrant.id,
      created_by: utilisateurId,
    })
    .select()
    .single();
  if (e3) throw e3;
  return data;
}

async function getTransfertsRecents() {
  const { data, error } = await supabaseClient
    .from("transferts")
    .select("*, source:caisse_source_id(nom), dest:caisse_dest_id(nom)")
    .order("created_at", { ascending: false })
    .limit(10);
  if (error) throw error;
  return data;
}
