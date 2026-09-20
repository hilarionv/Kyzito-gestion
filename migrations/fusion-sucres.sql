-- À exécuter dans le SQL Editor de Supabase.
-- Fusionne Sprite / Coca Cola / Fanta en un seul produit "Sucrés"
-- (même prix dans chaque resto, donc pas de perte d'info).

delete from produits where nom in ('Sprite', 'Coca Cola', 'Fanta');

insert into produits (secteur_id, nom, categorie, prix_vente, emplacement, prix_variable)
select s.id, v.nom, 'boisson', v.prix, v.emplacement, false
from (select id from secteurs where type = 'bar_restaurant') s,
(values
  ('Sucrés', 1000, 'resto_1'),
  ('Sucrés', 1200, 'resto_2')
) as v(nom, prix, emplacement);
