-- À coller et exécuter dans le SQL Editor de Supabase, AVANT le
-- fichier produits-menu.sql

-- 1. On passe les colonnes "categorie" en texte libre plutôt qu'un
--    enum fermé — plus simple à faire évoluer (ex. ajouter
--    "nourriture" unifiée au lieu de nourriture_resto1/resto2).
alter table produits alter column categorie type text;
alter table mouvements_caisse alter column categorie type text;

-- 2. Un produit "nourriture" est désormais partagé entre les deux
--    restaurants (même carte, même prix) — categorie = 'nourriture'.
--    Un produit "boisson" peut varier de prix selon le restaurant —
--    categorie = 'boisson', et le champ emplacement précise lequel.

alter table produits add column if not exists emplacement text; -- null = valable partout (nourriture) ; 'resto_1' / 'resto_2' pour les boissons
alter table produits add column if not exists prix_variable boolean not null default false; -- ex. poisson braisé : prix selon le poids/poisson, pas un prix fixe

-- 3. On recrée la fonction enregistrer_vente pour accepter la
--    catégorie en texte libre (au lieu de l'ancien enum).
drop function if exists enregistrer_vente(uuid, uuid, uuid, numeric, categorie_vente, uuid);

create or replace function enregistrer_vente(
  p_caisse_id uuid,
  p_session_id uuid,
  p_produit_id uuid,
  p_montant numeric,
  p_categorie text,
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
