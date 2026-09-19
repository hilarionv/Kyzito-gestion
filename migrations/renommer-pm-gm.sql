-- À exécuter dans le SQL Editor de Supabase.
-- Harmonise le nommage des boissons à prix double (petit/grand) avec
-- celui des pizzas (PM/GM).

update produits set nom = replace(nom, '(petit)', '(PM)') where nom like '%(petit)%';
update produits set nom = replace(nom, '(grand)', '(GM)') where nom like '%(grand)%';
