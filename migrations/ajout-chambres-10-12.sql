-- À exécuter dans le SQL Editor de Supabase.
-- Ajoute 2 chambres simples de plus (10 et 11), pour un total de
-- 10 chambres simples + 1 VIP (12) + 1 suite (7) = 12 chambres.

insert into chambres (type_chambre_id, numero)
select (select id from types_chambres where nom = 'Simple'), numero
from unnest(array['10','11']) as numero;
