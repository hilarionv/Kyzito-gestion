-- À exécuter dans le SQL Editor, après migration-menu.sql et
-- produits-menu.sql (déjà exécutés précédemment)

-- 1. La liqueur a les mêmes prix dans les deux restos : on la rend
--    "partagée" (emplacement = null) au lieu de resto_1 uniquement,
--    pour ne pas avoir à la dupliquer.
update produits
set emplacement = null
where categorie = 'boisson'
  and nom in ('JB', 'Jack Daniel', 'Bailey''s', 'Black Label', 'Chivas', 'Red Label', 'Grant''s', 'Martini', 'Gordon''s');

-- 2. Prix du resto 2 (différents pour bières, jus, vins, sucrées,
--    boissons énergisantes)
insert into produits (secteur_id, nom, categorie, prix_vente, emplacement, prix_variable)
select s.id, v.nom, v.categorie, v.prix, v.emplacement, v.prix_variable
from (select id from secteurs where type = 'bar_restaurant') s,
(values
  -- Bières
  ('Royal Dutch', 'boisson', 1200, 'resto_2', false),
  ('Flag (petit)', 'boisson', 1200, 'resto_2', false),
  ('Flag (grand)', 'boisson', 1700, 'resto_2', false),
  ('Cody''s', 'boisson', 1200, 'resto_2', false),
  ('Gold', 'boisson', 1200, 'resto_2', false),
  ('Gazelle (petit)', 'boisson', 1200, 'resto_2', false),
  ('Gazelle (grand)', 'boisson', 1700, 'resto_2', false),
  ('Heineken (petit)', 'boisson', 2200, 'resto_2', false),
  ('Heineken (grand)', 'boisson', 2700, 'resto_2', false),
  ('Desparados', 'boisson', 2700, 'resto_2', false),
  ('Master', 'boisson', 1700, 'resto_2', false),
  ('33 export', 'boisson', 1200, 'resto_2', false),

  -- Jus locaux
  ('Bouteille Jus', 'boisson', 3700, 'resto_2', false),
  ('Verre Jus', 'boisson', 1200, 'resto_2', false),

  -- Vins
  ('Don Garcia (petit)', 'boisson', 2000, 'resto_2', false),
  ('Don Garcia (grand)', 'boisson', 3500, 'resto_2', false),
  ('Saint Sernin (petit)', 'boisson', 2000, 'resto_2', false),
  ('Saint Sernin (grand)', 'boisson', 3500, 'resto_2', false),
  ('Baron', 'boisson', 3500, 'resto_2', false),
  ('Lumière de France', 'boisson', 3500, 'resto_2', false),

  -- Sucrées
  ('Sprite', 'boisson', 1200, 'resto_2', false),
  ('Coca Cola', 'boisson', 1200, 'resto_2', false),
  ('Fanta', 'boisson', 1200, 'resto_2', false),

  -- Boissons alcoolisées-énergisantes
  ('Vody', 'boisson', 1200, 'resto_2', false),
  ('Sagress', 'boisson', 1200, 'resto_2', false),
  ('3x', 'boisson', 1200, 'resto_2', false)
) as v(nom, categorie, prix, emplacement, prix_variable);
