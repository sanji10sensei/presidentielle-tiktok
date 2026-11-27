# presidentielle-tiktok

Chaîne semi-automatisée de vidéos TikTok sur la présidentielle 2027 : suivi de la campagne et comparaison des programmes des candidats déclarés.

Principe : aucune affirmation n'est publiée sans une position vérifiée, rattachée à une source datée. Les étapes de collecte et de montage sont automatisées ; la vérification des positions et la validation finale des vidéos restent humaines.

## Arborescence

```
presidentielle-tiktok/
├── CLAUDE.md                     règles permanentes lues par Claude à chaque exécution
├── README.md
├── sources_a_surveiller.md       candidats, partis, presse, institutions, domaines autorisés
├── db/
│   ├── schema_presidentielle.sql schéma de la base (PostgreSQL, compatible Supabase)
│   ├── migrations/               modifications successives du schéma
│   ├── installation_complete.sql schéma et migrations assemblés (généré par assembler_installation.py)
│   ├── donnees_initiales.sql     thèmes et candidats de départ
│   └── tests/                    tests des garde-fous et de la sécurité (node db/tests/*.mjs)
├── prompts/
│   ├── 01_ingestion.md           collecte quotidienne → positions en brouillon
│   ├── 02_generation_script.md   script de vidéo lu uniquement dans v_positions_publiables
│   └── 03_relecture.md           contrôle indépendant des positions extraites
├── scripts/
│   ├── rendu.py                  script validé → fichier vidéo dans out/ (squelette)
│   └── publier_tiktok.py         vidéo validée → TikTok, puis traçage en base (squelette)
├── video/
│   ├── templates/                gabarits de montage
│   └── assets/                   polices, habillage, jingles
├── dashboard/
│   └── README.md                 tableau de validation de l'éditeur (à développer)
└── rapports/                     bilans des exécutions et propositions de modification
```

## Chaîne

1. **Ingestion** (`prompts/01_ingestion.md`) : sources → `sources` et `positions` au statut `brouillon`.
2. **Relecture automatique** (`prompts/03_relecture.md`) : verdict par position, sans écriture en base.
3. **Vérification humaine** (`dashboard/`) : passage des positions à `verifie`.
4. **Génération** (`prompts/02_generation_script.md`) : script JSON où chaque phrase pointe vers un `position_id`.
5. **Rendu** (`scripts/rendu.py`) puis **validation humaine** de la vidéo (`dashboard/`).
6. **Publication** (`scripts/publier_tiktok.py`) des seules vidéos au statut `valide`.

## Mise en route

1. Créer un projet Supabase, puis dans son éditeur SQL exécuter `db/installation_complete.sql` (schéma et migrations assemblés), puis `db/donnees_initiales.sql` (thèmes et candidats). Après toute nouvelle migration, régénérer ce fichier avec `python3 db/assembler_installation.py`.
2. Configurer l'environnement cloud de Claude Code (réseau « Custom », domaines de la section 8 de `sources_a_surveiller.md`, clés en secrets réseau).
3. Créer la routine quotidienne avec le contenu de `prompts/01_ingestion.md`.
4. Lancer « Run now », relire le déroulé et les lignes insérées, puis corriger le prompt si besoin.
