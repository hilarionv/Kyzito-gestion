-- À exécuter EN PREMIER dans le SQL Editor, avant tout le reste
-- (migrations et insertion du menu). Crée les 4 secteurs et une
-- caisse de base pour chacun. Sans exécution, les scripts suivants
-- insèrent silencieusement 0 ligne.

insert into secteurs (nom, type)
select 'Bar-restaurant', 'bar_restaurant'
where not exists (select 1 from secteurs where type = 'bar_restaurant');

insert into secteurs (nom, type)
select 'Salle de conférence', 'salle_conference'
where not exists (select 1 from secteurs where type = 'salle_conference');

insert into secteurs (nom, type)
select 'Chambres', 'chambres'
where not exists (select 1 from secteurs where type = 'chambres');

insert into secteurs (nom, type)
select 'Piscines', 'piscines'
where not exists (select 1 from secteurs where type = 'piscines');

-- Une caisse de base par secteur (celle du bar-restaurant sera
-- ensuite scindée en resto_1 / CLK par migration-clk-caisse.sql —
-- normal si tu la relances après ce script, elle est idempotente).
insert into caisses (secteur_id, nom)
select s.id, 'Caisse ' || s.nom
from secteurs s
where not exists (select 1 from caisses c where c.secteur_id = s.id);
