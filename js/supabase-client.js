// ============================================================
// Config Supabase — remplace ces deux valeurs par celles de ton
// projet (Supabase > Project Settings > API)
// ============================================================
const SUPABASE_URL = "https://epefchkcwxzuvmlywzji.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_pvxQRV2__xgKrYx5wt8RMQ_iqdodB3x";

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ------------------------------------------------------------
// Session locale (utilisateur connecté sur cet appareil)
// ------------------------------------------------------------
function getUtilisateurLocal() {
  const raw = localStorage.getItem("utilisateur");
  return raw ? JSON.parse(raw) : null;
}

function setUtilisateurLocal(utilisateur) {
  localStorage.setItem("utilisateur", JSON.stringify(utilisateur));
}

function deconnecter() {
  localStorage.removeItem("utilisateur");
  window.location.href = "../index.html";
}

// ------------------------------------------------------------
// Connexion par code d'accès (admin ou serveur)
// ------------------------------------------------------------
async function connecterAvecCode(code) {
  const { data, error } = await supabaseClient
    .from("utilisateurs")
    .select("*")
    .eq("code_acces", code)
    .single();

  if (error || !data) {
    throw new Error("Code invalide");
  }
  setUtilisateurLocal(data);
  return data;
}

// ------------------------------------------------------------
// Secteurs & caisses
// ------------------------------------------------------------
async function getSecteurs() {
  const { data, error } = await supabaseClient.from("secteurs").select("*");
  if (error) throw error;
  return data;
}

async function getCaisseParSecteur(secteurId) {
  const { data, error } = await supabaseClient
    .from("caisses")
    .select("*")
    .eq("secteur_id", secteurId)
    .single();
  if (error) throw error;
  return data;
}

async function getCaisseParEmplacement(secteurId, emplacement) {
  const { data, error } = await supabaseClient
    .from("caisses")
    .select("*")
    .eq("secteur_id", secteurId)
    .eq("emplacement", emplacement)
    .single();
  if (error) throw error;
  return data;
}

// ------------------------------------------------------------
// Sessions de caisse (bar-restaurant)
// ------------------------------------------------------------
async function getSessionOuverte(caisseId) {
  const { data, error } = await supabaseClient
    .from("sessions_caisse")
    .select("*")
    .eq("caisse_id", caisseId)
    .eq("statut", "ouverte")
    .order("ouverte_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function ouvrirSession(caisseId, equipe, montantOuverture, utilisateurId) {
  const { data, error } = await supabaseClient
    .from("sessions_caisse")
    .insert({
      caisse_id: caisseId,
      equipe,
      montant_ouverture: montantOuverture,
      ouverte_par: utilisateurId,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function cloturerSession(sessionId, montantTheorique, montantReel, utilisateurId) {
  const { data, error } = await supabaseClient
    .from("sessions_caisse")
    .update({
      montant_theorique: montantTheorique,
      montant_reel: montantReel,
      ecart: montantReel - montantTheorique,
      statut: "cloturee",
      cloturee_par: utilisateurId,
      cloturee_at: new Date().toISOString(),
    })
    .eq("id", sessionId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

// ------------------------------------------------------------
// Produits & ventes (grille produits, boutons "+")
// ------------------------------------------------------------
async function getProduits(secteurId) {
  const { data, error } = await supabaseClient
    .from("produits")
    .select("*")
    .eq("secteur_id", secteurId)
    .order("nom");
  if (error) throw error;
  return data;
}

// Enregistre une vente ET décrémente le stock frigo en une seule opération.
// Nécessite une fonction Postgres côté Supabase (voir schema.sql /
// à créer : rpc "enregistrer_vente") pour garantir l'atomicité.
async function enregistrerVente({ caisseId, sessionId, produit, utilisateurId, modePaiement }) {
  const { data, error } = await supabaseClient.rpc("enregistrer_vente", {
    p_caisse_id: caisseId,
    p_session_id: sessionId,
    p_produit_id: produit.id,
    p_montant: produit.prix_vente,
    p_categorie: produit.categorie,
    p_utilisateur_id: utilisateurId,
    p_mode_paiement: modePaiement || "especes",
  });
  if (error) throw error;
  return data;
}

async function getTotalEspecesSession(sessionId) {
  const { data, error } = await supabaseClient
    .from("mouvements_caisse")
    .select("type, montant, mode_paiement")
    .eq("session_id", sessionId);
  if (error) throw error;
  return data.reduce((total, m) => {
    if (m.type === "vente" && m.mode_paiement !== "especes") return total;
    if (m.type === "vente" || m.type === "transfert_entrant") return total + m.montant;
    if (m.type === "achat" || m.type === "transfert_sortant") return total - m.montant;
    return total;
  }, 0);
}

async function annulerVente(sessionId, produitId, categorie) {
  const { data: derniere, error: e1 } = await supabaseClient
    .from("mouvements_caisse")
    .select("*")
    .eq("session_id", sessionId)
    .eq("produit_id", produitId)
    .eq("type", "vente")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (e1) throw e1;
  if (!derniere) return null;

  const { error: e2 } = await supabaseClient.from("mouvements_caisse").delete().eq("id", derniere.id);
  if (e2) throw e2;

  if (categorie === "boisson") {
    const { data: produit, error: e3 } = await supabaseClient
      .from("produits")
      .select("stock")
      .eq("id", produitId)
      .single();
    if (e3) throw e3;
    await supabaseClient.from("produits").update({ stock: produit.stock + 1 }).eq("id", produitId);
  }

  return derniere.montant;
}

// ------------------------------------------------------------
// Dépenses / prélèvements en cours de session
// ------------------------------------------------------------
async function enregistrerDepense({ caisseId, sessionId, montant, description, categorie, utilisateurId }) {
  const { data, error } = await supabaseClient
    .from("mouvements_caisse")
    .insert({
      caisse_id: caisseId,
      session_id: sessionId,
      type: "achat",
      montant,
      description,
      categorie,
      created_by: utilisateurId,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function getTotalSession(sessionId) {
  const { data, error } = await supabaseClient
    .from("mouvements_caisse")
    .select("type, montant")
    .eq("session_id", sessionId);
  if (error) throw error;
  return data.reduce((total, m) => {
    if (m.type === "vente" || m.type === "transfert_entrant") return total + m.montant;
    if (m.type === "achat" || m.type === "transfert_sortant") return total - m.montant;
    return total;
  }, 0);
}

async function getMouvementsDuJour(date) {
  const debut = date + "T00:00:00";
  const fin = date + "T23:59:59";
  const { data, error } = await supabaseClient
    .from("mouvements_caisse")
    .select("*, produits(nom), caisses(nom, secteurs(nom))")
    .gte("created_at", debut)
    .lte("created_at", fin)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data;
}

async function getDetailSession(sessionId) {
  const { data, error } = await supabaseClient
    .from("mouvements_caisse")
    .select("type, montant, mode_paiement")
    .eq("session_id", sessionId);
  if (error) throw error;

  const detail = { especes: 0, wave: 0, orange_money: 0, depenses: 0 };
  data.forEach(m => {
    if (m.type === "vente") {
      if (m.mode_paiement === "wave") detail.wave += m.montant;
      else if (m.mode_paiement === "orange_money") detail.orange_money += m.montant;
      else detail.especes += m.montant;
    } else if (m.type === "achat") {
      detail.depenses += m.montant;
    }
  });
  return detail;
}

// ------------------------------------------------------------
// Comptabilité (vues v_compta_journaliere / v_compta_mensuelle)
// ------------------------------------------------------------
async function getComptaJournaliere(date) {
  const { data, error } = await supabaseClient
    .from("v_compta_journaliere")
    .select("*")
    .eq("date", date);
  if (error) throw error;
  return data;
}

async function getComptaMensuelle(mois) {
  const { data, error } = await supabaseClient
    .from("v_compta_mensuelle")
    .select("*")
    .eq("mois", mois);
  if (error) throw error;
  return data;
}
