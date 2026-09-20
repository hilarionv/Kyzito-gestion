-- À exécuter dans le SQL Editor de Supabase.
-- Ajoute le secteur "Shootings photo", sa caisse, et la table de
-- réservations avec 3 paliers de prix (2500 / 5000 / 10000).

-- On passe secteurs.type en texte libre (au lieu d'un enum fermé),
-- pour pouvoir ajouter ce nouveau secteur sans complication d'enum.
alter table secteurs alter column type type text;

insert into secteurs (nom, type)
select 'Shootings photo', 'shooting_photo'
where not exists (select 1 from secteurs where type = 'shooting_photo');

insert into caisses (secteur_id, nom)
select id, 'Caisse Shootings photo'
from secteurs
where type = 'shooting_photo'
  and not exists (
    select 1 from caisses c where c.secteur_id = secteurs.id
  );

create table if not exists reservations_shooting (
  id uuid primary key default gen_random_uuid(),
  date date not null default current_date,
  client_nom text not null,
  prix numeric(12,2) not null,
  statut statut_reservation not null default 'reservee',
  caisse_id uuid references caisses(id),
  created_by uuid references utilisateurs(id),
  created_at timestamptz not null default now()
);

alter table reservations_shooting disable row level security;
