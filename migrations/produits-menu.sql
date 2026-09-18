-- À exécuter APRÈS migration-menu.sql
-- Catalogue "Complexe le Kyzito" — bar-restaurant

insert into produits (secteur_id, nom, categorie, prix_vente, emplacement, prix_variable)
select s.id, v.nom, v.categorie, v.prix, v.emplacement, v.prix_variable
from (select id from secteurs where type = 'bar_restaurant') s,
(values
  -- ===== BOISSONS — resto 1 (Complexe le Kyzito) =====
  -- Bières
  ('Royal Dutch', 'boisson', 1000, 'resto_1', false),
  ('Flag (petit)', 'boisson', 1000, 'resto_1', false),
  ('Flag (grand)', 'boisson', 1500, 'resto_1', false),
  ('Cody''s', 'boisson', 1000, 'resto_1', false),
  ('Gold', 'boisson', 1200, 'resto_1', false),
  ('Gazelle (petit)', 'boisson', 1000, 'resto_1', false),
  ('Gazelle (grand)', 'boisson', 1500, 'resto_1', false),
  ('Heineken (petit)', 'boisson', 2000, 'resto_1', false),
  ('Heineken (grand)', 'boisson', 2500, 'resto_1', false),
  ('Desparados', 'boisson', 2500, 'resto_1', false),
  ('Master', 'boisson', 1500, 'resto_1', false),
  ('33 export', 'boisson', 1000, 'resto_1', false),

  -- Jus locaux
  ('Bouteille Jus', 'boisson', 3500, 'resto_1', false),
  ('Verre Jus', 'boisson', 1000, 'resto_1', false),

  -- Vins
  ('Don Garcia (petit)', 'boisson', 1700, 'resto_1', false),
  ('Don Garcia (grand)', 'boisson', 3200, 'resto_1', false),
  ('Saint Sernin (petit)', 'boisson', 1700, 'resto_1', false),
  ('Saint Sernin (grand)', 'boisson', 3200, 'resto_1', false),
  ('Baron', 'boisson', 3200, 'resto_1', false),
  ('Lumière de France', 'boisson', 3200, 'resto_1', false),

  -- Liqueur
  ('JB', 'boisson', 4000, 'resto_1', false),
  ('Jack Daniel', 'boisson', 4500, 'resto_1', false),
  ('Bailey''s', 'boisson', 4000, 'resto_1', false),
  ('Black Label', 'boisson', 4500, 'resto_1', false),
  ('Chivas', 'boisson', 4500, 'resto_1', false),
  ('Red Label', 'boisson', 4000, 'resto_1', false),
  ('Grant''s', 'boisson', 4000, 'resto_1', false),
  ('Martini', 'boisson', 4000, 'resto_1', false),
  ('Gordon''s', 'boisson', 4000, 'resto_1', false),

  -- Sucrées
  ('Sprite', 'boisson', 1000, 'resto_1', false),
  ('Coca Cola', 'boisson', 1000, 'resto_1', false),
  ('Fanta', 'boisson', 1000, 'resto_1', false),

  -- Boissons alcoolisées-énergisantes
  ('Vody', 'boisson', 1000, 'resto_1', false),
  ('Sagress', 'boisson', 1000, 'resto_1', false),
  ('3x', 'boisson', 1000, 'resto_1', false),

  -- ===== NOURRITURE — partagée resto 1 & resto 2 =====
  -- La ferme au kyto
  ('Dibi poulet 500g', 'nourriture', 3500, null, false),
  ('Poulet braisé 1kg', 'nourriture', 7000, null, false),
  ('Dibi mouton 500g', 'nourriture', 4000, null, false),
  ('Entrecôte de bœuf', 'nourriture', 4000, null, false),
  ('Poulet braisé 500g', 'nourriture', 3500, null, false),
  ('Dibi porc 500g', 'nourriture', 4000, null, false),
  ('Dibi phacochère 500g', 'nourriture', 3000, null, false),
  ('Supplément accompagnement', 'nourriture', 1000, null, false),

  -- Plat du jour
  ('Plat du jour + dessert', 'nourriture', 2000, null, false),

  -- À la pêche
  ('Poisson braisé', 'nourriture', 0, null, true),
  ('Poisson frit à l''ivoirienne', 'nourriture', 2500, null, false),
  ('Poisson sauce tomate', 'nourriture', 3500, null, false),
  ('Poulet pané', 'nourriture', 4000, null, false),

  -- Pizzas
  ('Pizza Norvégienne (PM)', 'nourriture', 4000, null, false),
  ('Pizza Norvégienne (GM)', 'nourriture', 6000, null, false),
  ('Pizza Bolognaise (PM)', 'nourriture', 4000, null, false),
  ('Pizza Bolognaise (GM)', 'nourriture', 6000, null, false),
  ('Pizza Reine (PM)', 'nourriture', 4000, null, false),
  ('Pizza Reine (GM)', 'nourriture', 6000, null, false),

  -- La pâte de mama
  ('Omelette nature', 'nourriture', 1500, null, false),
  ('Omelette jambon fromage', 'nourriture', 1500, null, false),
  ('Spaghetti bolognaise', 'nourriture', 2500, null, false),
  ('Tagliatelle au poulet', 'nourriture', 3500, null, false),

  -- Chez l'oncle Sam
  ('Chawarma', 'nourriture', 1500, null, false),
  ('Hamburger simple', 'nourriture', 1600, null, false),
  ('Hamburger double', 'nourriture', 2800, null, false),
  ('Tacos poulet', 'nourriture', 2500, null, false),
  ('Tacos viande', 'nourriture', 2500, null, false)
) as v(nom, categorie, prix, emplacement, prix_variable);
