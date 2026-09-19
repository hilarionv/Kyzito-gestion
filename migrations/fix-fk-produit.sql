-- À exécuter dans le SQL Editor de Supabase.
-- Corrige "Dernières ventes" (et tout écran qui joint mouvements_caisse
-- à produits) en ajoutant la clé étrangère manquante.

alter table mouvements_caisse
  add constraint mouvements_caisse_produit_id_fkey
  foreign key (produit_id) references produits(id);
