-- À exécuter dans le SQL Editor de Supabase.
-- 8 chambres simples, 1 VIP (chambre 12), 1 suite (chambre 7).
-- Numérotation des 8 simples : 1,2,3,4,5,6,8,9 (7 et 12 réservées
-- à la suite et à la VIP) — dis-moi si tu veux une autre numérotation.

insert into types_chambres (nom, prix_nuit) values
  ('Simple', 25000),
  ('VIP', 40000),
  ('Suite', 50000);

insert into chambres (type_chambre_id, numero)
select (select id from types_chambres where nom = 'Simple'), numero
from unnest(array['1','2','3','4','5','6','8','9']) as numero;

insert into chambres (type_chambre_id, numero)
values ((select id from types_chambres where nom = 'VIP'), '12');

insert into chambres (type_chambre_id, numero)
values ((select id from types_chambres where nom = 'Suite'), '7');
