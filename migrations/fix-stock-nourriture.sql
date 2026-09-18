-- À exécuter dans le SQL Editor de Supabase.
-- La nourriture n'a pas de gestion de stock (pas de livraison/frigo
-- suivie) — seule la boisson doit décrémenter le stock à la vente.

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

  if p_categorie = 'boisson' then
    update produits set stock_frigo = stock_frigo - 1 where id = p_produit_id;

    insert into mouvements_stock (produit_id, type, quantite, date, created_by)
    values (p_produit_id, 'vente', -1, current_date, p_utilisateur_id);
  end if;

  return v_mouvement_id;
end;
$$;
