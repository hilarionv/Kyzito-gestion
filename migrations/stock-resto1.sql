-- À exécuter dans le SQL Editor de Supabase, APRÈS fusion-sucres.sql.
-- Stock du Resto 1 uniquement (grenier + frigo), d'après les photos
-- du 19 septembre 2026.

update produits set stock_grenier = 480, stock_frigo = 44
  where nom = 'Royal Dutch' and emplacement = 'resto_1';

update produits set stock_grenier = 60, stock_frigo = 3
  where nom = 'Don Garcia (GM)' and emplacement = 'resto_1';

update produits set stock_grenier = 108, stock_frigo = 3
  where nom = 'Don Garcia (PM)' and emplacement = 'resto_1';

update produits set stock_grenier = 72, stock_frigo = 18
  where nom = '3x' and emplacement = 'resto_1';

update produits set stock_grenier = 12, stock_frigo = 11
  where nom = 'Saint Sernin (GM)' and emplacement = 'resto_1';

update produits set stock_grenier = 48, stock_frigo = 17
  where nom = 'Vody' and emplacement = 'resto_1';

update produits set stock_grenier = 192, stock_frigo = 37
  where nom = 'Cody''s' and emplacement = 'resto_1';

update produits set stock_grenier = 107, stock_frigo = 28
  where nom = 'Sucrés' and emplacement = 'resto_1';

update produits set stock_grenier = 92, stock_frigo = 17
  where nom = 'Gazelle (GM)' and emplacement = 'resto_1';

update produits set stock_grenier = 62, stock_frigo = 11
  where nom = 'Flag (PM)' and emplacement = 'resto_1';

update produits set stock_grenier = 43, stock_frigo = 9
  where nom = 'Gazelle (PM)' and emplacement = 'resto_1';

update produits set stock_grenier = 12, stock_frigo = 18
  where nom = 'Flag (GM)' and emplacement = 'resto_1';
