-- À exécuter dans le SQL Editor de Supabase (après ajout-shootings.sql
-- déjà exécuté). Remplace le système de réservation par un simple
-- compteur de ventes, comme la piscine.

drop table if exists reservations_shooting;

create table if not exists ventes_shooting (
  id uuid primary key default gen_random_uuid(),
  date date not null default current_date,
  prix_unitaire numeric(12,2) not null,
  caisse_id uuid references caisses(id),
  created_by uuid references utilisateurs(id),
  created_at timestamptz not null default now()
);

alter table ventes_shooting disable row level security;
