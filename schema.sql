-- ============================================================
-- SCHEMA — Application de gestion hôtel (bar-restaurant,
-- salle de conférence, chambres, piscines)
-- Postgres / Supabase
-- ============================================================

-- ------------------------------------------------------------
-- 1. UTILISATEURS & RÔLES
-- ------------------------------------------------------------
-- Deux rôles seulement : admin (le gérant) et serveur (code partagé).
-- Pas de compte individuel pour chaque serveur — un seul identifiant
-- "serveur" suffit, mais on garde created_by / closed_by en texte libre
-- (prénom saisi à la volée) pour tracer qui a fait quoi sans compte dédié.

create type role_utilisateur as enum ('admin', 'serveur');

create table utilisateurs (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  role role_utilisateur not null,
  code_acces text not null,        -- code/PIN partagé pour les serveurs
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2. SECTEURS & CAISSES
-- ------------------------------------------------------------
-- Un secteur = une source de revenu (bar-restaurant, salle, chambres,
-- piscines). Chaque secteur qui manipule de l'argent a une caisse.

create type type_secteur as enum ('bar_restaurant', 'salle_conference', 'chambres', 'piscines');

create table secteurs (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  type type_secteur not null
);

create table caisses (
  id uuid primary key default gen_random_uuid(),
  secteur_id uuid not null references secteurs(id),
  nom text not null,               -- ex. "Caisse bar-restaurant"
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 3. SESSIONS DE CAISSE (équipe matin/soir)
-- ------------------------------------------------------------
-- Une session = un service (matin ou soir) au bar-restaurant.
-- Remplace le cahier papier : on ouvre, on enregistre les mouvements,
-- on clôture avec comptage réel, l'écart se calcule automatiquement.

create type equipe_service as enum ('matin', 'soir');
create type statut_session as enum ('ouverte', 'cloturee');

create table sessions_caisse (
  id uuid primary key default gen_random_uuid(),
  caisse_id uuid not null references caisses(id),
  equipe equipe_service not null,
  date date not null default current_date,
  montant_ouverture numeric(12,2) not null default 0,
  montant_theorique numeric(12,2),      -- calculé : ouverture + ventes - sorties
  montant_reel numeric(12,2),           -- saisi au comptage par le gérant
  ecart numeric(12,2),                  -- reel - theorique
  statut statut_session not null default 'ouverte',
  ouverte_par uuid references utilisateurs(id),
  cloturee_par uuid references utilisateurs(id),
  ouverte_at timestamptz not null default now(),
  cloturee_at timestamptz
);

-- ------------------------------------------------------------
-- 4. MOUVEMENTS DE CAISSE (ventes, achats, transferts)
-- ------------------------------------------------------------
-- Chaque entrée/sortie d'argent dans une caisse, qu'elle soit
-- rattachée à une session (bar-restaurant) ou directe (hôtel, salle,
-- piscines qui n'ont pas forcément de session matin/soir).

create type type_mouvement as enum ('vente', 'achat', 'transfert_entrant', 'transfert_sortant');
create type categorie_vente as enum ('boisson', 'nourriture_resto1', 'nourriture_resto2', 'autre');

create table mouvements_caisse (
  id uuid primary key default gen_random_uuid(),
  caisse_id uuid not null references caisses(id),
  session_id uuid references sessions_caisse(id),  -- nullable : hors session pour hôtel/salle/piscines
  type type_mouvement not null,
  categorie categorie_vente,                        -- utile surtout pour les ventes bar/resto
  montant numeric(12,2) not null,
  description text,
  produit_id uuid,                                  -- lien optionnel vers un produit vendu (voir section stock)
  quantite integer,                                  -- si vente d'un produit avec quantité
  created_by uuid references utilisateurs(id),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 5. TRANSFERTS INTER-CAISSES
-- ------------------------------------------------------------
-- Un transfert n'est PAS une dépense : il déplace de l'argent d'une
-- caisse à une autre (n'importe quels secteurs). Il génère deux lignes
-- dans mouvements_caisse (transfert_sortant côté source, transfert_entrant
-- côté destination) pour que chaque caisse garde un solde juste, tout
-- en étant neutralisé dans la compta globale.

create table transferts (
  id uuid primary key default gen_random_uuid(),
  caisse_source_id uuid not null references caisses(id),
  caisse_dest_id uuid not null references caisses(id),
  montant numeric(12,2) not null,
  motif text,
  date date not null default current_date,
  mouvement_sortant_id uuid references mouvements_caisse(id),
  mouvement_entrant_id uuid references mouvements_caisse(id),
  created_by uuid references utilisateurs(id),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 6. STOCK (bar-restaurant)
-- ------------------------------------------------------------
-- Livraison hebdo (jeudi) -> grenier -> transfert vers frigo au
-- fur et à mesure -> décrémenté automatiquement par les ventes.

create table produits (
  id uuid primary key default gen_random_uuid(),
  secteur_id uuid not null references secteurs(id),
  nom text not null,
  categorie categorie_vente not null,
  prix_vente numeric(12,2) not null,
  stock_grenier integer not null default 0,
  stock_frigo integer not null default 0
);

create type type_mouvement_stock as enum ('livraison', 'grenier_vers_frigo', 'vente');

create table mouvements_stock (
  id uuid primary key default gen_random_uuid(),
  produit_id uuid not null references produits(id),
  type type_mouvement_stock not null,
  quantite integer not null,           -- positif ou négatif selon le sens
  fournisseur text,                    -- pour les livraisons
  date date not null default current_date,
  created_by uuid references utilisateurs(id),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 7. CHAMBRES (hôtel)
-- ------------------------------------------------------------

create table types_chambres (
  id uuid primary key default gen_random_uuid(),
  nom text not null,                   -- ex. "Standard", "Confort", "Suite"
  prix_nuit numeric(12,2) not null
);

create table chambres (
  id uuid primary key default gen_random_uuid(),
  type_chambre_id uuid not null references types_chambres(id),
  numero text not null
);

create type statut_reservation as enum ('reservee', 'occupee', 'terminee', 'annulee');

create table reservations_chambres (
  id uuid primary key default gen_random_uuid(),
  chambre_id uuid not null references chambres(id),
  client_nom text not null,
  date_debut date not null,
  date_fin date not null,
  montant_total numeric(12,2),
  statut statut_reservation not null default 'reservee',
  caisse_id uuid references caisses(id),   -- caisse hôtel où le paiement est enregistré
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 8. SALLE DE CONFÉRENCE
-- ------------------------------------------------------------
-- Tarif fixe (150 000 FCFA/jour), réservation simple.

create table reservations_salle (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  client_nom text,
  montant numeric(12,2) not null default 150000,
  statut statut_reservation not null default 'reservee',
  caisse_id uuid references caisses(id),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 9. PISCINES
-- ------------------------------------------------------------
-- Tickets journaliers pour les clients non-résidents.

create table ventes_piscine (
  id uuid primary key default gen_random_uuid(),
  date date not null default current_date,
  nombre_tickets integer not null,
  prix_unitaire numeric(12,2) not null,
  montant_total numeric(12,2) generated always as (nombre_tickets * prix_unitaire) stored,
  caisse_id uuid references caisses(id),
  created_by uuid references utilisateurs(id),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 10. DÉPENSES PARTAGÉES MENSUELLES
-- ------------------------------------------------------------
-- Dépenses réglées une fois par mois sur le cumul de plusieurs
-- secteurs (salaires, factures...), pas imputées à un secteur unique
-- au moment où elles surviennent.

create type type_depense_partagee as enum ('salaire', 'facture', 'autre');

create table depenses_partagees (
  id uuid primary key default gen_random_uuid(),
  mois integer not null,               -- 1-12
  annee integer not null,
  type type_depense_partagee not null,
  montant numeric(12,2) not null,
  description text,
  created_at timestamptz not null default now()
);

-- Table de liaison : quels secteurs sont concernés par cette dépense
-- (peut être 2 secteurs comme hôtel+restaurant, ou plus).
create table depenses_partagees_secteurs (
  depense_id uuid not null references depenses_partagees(id) on delete cascade,
  secteur_id uuid not null references secteurs(id),
  primary key (depense_id, secteur_id)
);

-- ------------------------------------------------------------
-- 11. VUE — COMPTABILITÉ GLOBALE (journalière + mensuelle)
-- ------------------------------------------------------------
-- Agrège les mouvements par secteur et par "journée comptable",
-- en excluant les transferts (neutres dans la vue globale).
--
-- IMPORTANT — journée comptable vs horloge :
-- Une session ouverte à 18h et clôturée à 1h du matin appartient
-- ENTIÈREMENT à la soirée où elle a été ouverte, même si certains
-- mouvements sont horodatés après minuit. On ne groupe donc jamais
-- par mc.created_at::date (l'heure réelle), mais par la date de la
-- session (sessions_caisse.date, fixée une fois pour toutes à
-- l'ouverture). Pour les caisses sans session (hôtel, salle,
-- piscines), qui n'ont pas ce problème de chevauchement de minuit,
-- on retombe sur la date réelle du mouvement.

create view v_compta_journaliere as
select
  s.id as secteur_id,
  s.nom as secteur_nom,
  coalesce(sc.date, mc.created_at::date) as date,
  sum(case when mc.type = 'vente' then mc.montant else 0 end) as total_ventes,
  sum(case when mc.type = 'achat' then mc.montant else 0 end) as total_depenses
from mouvements_caisse mc
join caisses c on c.id = mc.caisse_id
join secteurs s on s.id = c.secteur_id
left join sessions_caisse sc on sc.id = mc.session_id
where mc.type in ('vente', 'achat')   -- transferts exclus volontairement
group by s.id, s.nom, coalesce(sc.date, mc.created_at::date);

-- Vue mensuelle : même logique de journée comptable, agrégée par mois.
create view v_compta_mensuelle as
select
  secteur_id,
  secteur_nom,
  date_trunc('month', date)::date as mois,
  sum(total_ventes) as total_ventes,
  sum(total_depenses) as total_depenses,
  sum(total_ventes) - sum(total_depenses) as marge_brute
from v_compta_journaliere
group by secteur_id, secteur_nom, date_trunc('month', date);

-- ------------------------------------------------------------
-- 12. FONCTION — enregistrer une vente (atomique)
-- ------------------------------------------------------------
-- Utilisée par l'écran serveur (bouton "+") : crée le mouvement de
-- vente ET décrémente le stock frigo dans la même transaction, pour
-- que les deux ne puissent jamais se désynchroniser.

create or replace function enregistrer_vente(
  p_caisse_id uuid,
  p_session_id uuid,
  p_produit_id uuid,
  p_montant numeric,
  p_categorie categorie_vente,
  p_utilisateur_id uuid
) returns uuid
language plpgsql
as $$
declare
  v_mouvement_id uuid;
begin
  insert into mouvements_caisse (caisse_id, session_id, type, categorie, montant, produit_id, quantite, created_by)
  values (p_caisse_id, p_session_id, 'vente', p_categorie, p_montant, p_produit_id, 1, p_utilisateur_id)
  returning id into v_mouvement_id;

  update produits set stock_frigo = stock_frigo - 1 where id = p_produit_id;

  insert into mouvements_stock (produit_id, type, quantite, date, created_by)
  values (p_produit_id, 'vente', -1, current_date, p_utilisateur_id);

  return v_mouvement_id;
end;
$$;
