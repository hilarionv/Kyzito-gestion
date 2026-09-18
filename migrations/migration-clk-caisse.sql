-- À exécuter dans le SQL Editor, après les migrations précédentes.

-- Chaque caisse est maintenant rattachée à un "emplacement" (resto_1
-- ou resto_2/CLK), pour que chaque caissière ait sa propre caisse et
-- ses propres sessions, tout en partageant le même catalogue produits.
alter table caisses add column if not exists emplacement text;

-- La caisse existante du bar-restaurant devient celle du resto 1.
update caisses
set emplacement = 'resto_1'
where secteur_id = (select id from secteurs where type = 'bar_restaurant')
  and emplacement is null;

-- Nouvelle caisse pour CLK (resto 2), même secteur.
insert into caisses (secteur_id, nom, emplacement)
select id, 'Caisse CLK', 'resto_2'
from secteurs
where type = 'bar_restaurant';
