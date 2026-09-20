-- À exécuter dans le SQL Editor de Supabase.

alter table mouvements_caisse add column if not exists mode_paiement text not null default 'especes';
-- valeurs attendues : 'especes', 'wave', 'orange_money', 'autre'

drop function if exists enregistrer_vente(uuid, uuid, uuid, numeric, text, uuid);

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
    update produits set stock_frigo = stock_frigo - 1 where id = p_produit_id;

    insert into mouvements_stock (produit_id, type, quantite, date, created_by)
    values (p_produit_id, 'vente', -1, current_date, p_utilisateur_id);
  end if;

  return v_mouvement_id;
end;
$$;
