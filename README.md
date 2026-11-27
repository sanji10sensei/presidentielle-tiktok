# presidentielle-tiktok

Chaîne semi-automatisée de vidéos TikTok sur la présidentielle 2027 : suivi de la campagne et comparaison des programmes des candidats déclarés.

Principe : aucune affirmation n'est publiée sans une position vérifiée, rattachée à une source datée. Les étapes de collecte et de montage sont automatisées ; la vérification des positions et la validation finale des vidéos restent humaines.

## Contenu du dépôt

| chemin | rôle |
|---|---|
| `CLAUDE.md` | Règles permanentes lues par Claude à chaque exécution |
| `sources_a_surveiller.md` | Candidats, partis, presse, sources institutionnelles et domaines autorisés |
| `db/schema_presidentielle.sql` | Schéma de la base (PostgreSQL, compatible Supabase) |
| `db/migrations/` | Modifications successives du schéma |
| `prompts/` | Copies versionnées des prompts des routines |
| `rapports/` | Bilans des exécutions |

## Mise en route

1. Créer un projet Supabase et exécuter `db/schema_presidentielle.sql`.
2. Configurer l'environnement cloud de Claude Code (réseau « Custom », domaines de la section 8 de `sources_a_surveiller.md`, clés en secrets réseau).
3. Créer la routine quotidienne avec le contenu de `prompts/01_ingestion.md`.
4. Lancer « Run now », relire le déroulé et les lignes insérées, puis corriger le prompt si besoin.
