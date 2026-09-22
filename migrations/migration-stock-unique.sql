-- À exécuter dans le SQL Editor de Supabase.
-- Simplifie le stock : un seul champ "stock" par produit, au lieu de
-- grenier + frigo séparés.

alter table produits add column if not exists stock integer not null default 0;
update produits set stock = stock_frigo + stock_grenier;

-- On retire les anciennes colonnes — plus besoin, tout est dans "stock".
alter table produits drop column if exists stock_frigo;
alter table produits drop column if exists stock_grenier;

-- La fonction enregistrer_vente décrémente maintenant "stock" au lieu
-- de "stock_frigo".
create or replace function enregistrer_vente(
  p_caisse_id uuid,
  p_session_id uuid,
  p_produit_id uuid,
  p_montant numeric,
  p_categorie text,
  p_utilisateur_id uuid,
  p_mode_paiement text default 'especes'
) returns uuid
language plpgsql
as $$
declare
  v_mouvement_id uuid;
begin
  insert into mouvements_caisse (caisse_id, session_id, type, categorie, montant, produit_id, quantite, created_by, mode_paiement)
  values (p_caisse_id, p_session_id, 'vente', p_categorie, p_montant, p_produit_id, 1, p_utilisateur_id, p_mode_paiement)
  returning id into v_mouvement_id;

  if p_categorie = 'boisson' then
    update produits set stock = stock - 1 where id = p_produit_id;

    insert into mouvements_stock (produit_id, type, quantite, date, created_by)
    values (p_produit_id, 'vente', -1, current_date, p_utilisateur_id);
  end if;

  return v_mouvement_id;
end;
$$;
