# Gestion hôtel — projet de départ

## Mise en route

1. Crée un projet sur [supabase.com](https://supabase.com)
2. Va dans l'éditeur SQL de Supabase et colle le contenu de `schema.sql` (crée toutes les tables, vues et la fonction `enregistrer_vente`)
3. Ouvre `js/supabase-client.js` et remplace `SUPABASE_URL` et `SUPABASE_ANON_KEY` par les valeurs de ton projet (Project Settings > API)
4. Ajoute des données de départ dans Supabase : au minimum un secteur `bar_restaurant`, une caisse liée, quelques produits, et un utilisateur admin + un utilisateur serveur avec leurs `code_acces`
5. Héberge ces fichiers (GitHub Pages comme pour CMD fonctionne très bien) ou ouvre `index.html` en local pour tester

## Ce qui est déjà fonctionnel

- **index.html** — connexion par code d'accès (admin ou serveur), redirige vers le bon écran selon le rôle
- **serveur/vente.html** — grille produits avec boutons "+", ouverture/clôture de session de caisse avec calcul automatique de l'écart
- **admin/index.html** — tableau de bord avec le total du jour par secteur

## Ce qui reste à construire

- Écran dépense (`serveur/depense.html`, référencé mais pas encore créé)
- Écrans admin : stock/livraisons, chambres, transferts, dépenses partagées, rapports mensuels
- Écrans salle de conférence et piscines (compteurs simples, comme validé dans les maquettes)
- Le système de rappel automatique (notification si rien n'est enregistré à une heure donnée)
- Authentification plus robuste (actuellement le code d'accès est vérifié en clair côté client — à sécuriser avec les règles RLS de Supabase avant mise en prod)

## Structure

```
hotel-app/
  index.html              connexion
  schema.sql               à coller dans l'éditeur SQL Supabase
  css/style.css             styles communs
  js/supabase-client.js     connexion Supabase + toutes les fonctions de données
  admin/index.html          tableau de bord
  serveur/vente.html        écran de vente
```
