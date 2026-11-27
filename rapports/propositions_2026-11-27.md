# Propositions de modification : 27 novembre 2026

Points relevés en relisant les fichiers protégés (`CLAUDE.md`, `db/schema_presidentielle.sql`, `sources_a_surveiller.md`). Ils n'ont été modifiés qu'avec l'accord explicite de l'éditeur (point 2) ; le reste est à arbitrer par l'éditeur.

## Bloquant avant la première ingestion

1. **Statuts de candidats incohérents.** L'enum `statut_candidat` du schéma vaut `declare`, `declare_sous_condition`, `pressenti`, `retire`. Le fichier de sources utilise `ambition_annoncee` et `declare_peu_visible`, absents de l'enum : l'insertion des groupes B et D échouera. Proposition : migration `db/migrations/001_statuts_candidats.sql` ajoutant ces deux valeurs (`ALTER TYPE statut_candidat ADD VALUE ...`), ou alignement du fichier de sources sur l'enum.
   **Traité** : `db/migrations/001_statuts_candidats.sql`.

2. **Panel trop large et sans règle écrite.** Les 21 candidats du groupe A sont `dans_le_panel = oui`, alors que le MVP prévoyait environ 6 candidats, et la colonne `regle_panel` n'a pas de valeur proposée. Avec 21 candidats, un comparateur de 45 secondes laisse environ 2 secondes par candidat. Proposition : écrire la règle publique (par exemple « candidat déclaré d'une formation représentée au Parlement ») dans le fichier de sources, puis appliquer `dans_le_panel` en conséquence.
   **Décision de l'éditeur (27 novembre 2026)** : aucun lien avec les élus au Parlement. Tous les candidats officiellement déclarés (groupe A) sont collectés ; les groupes B, C et D ne font l'objet que d'une veille d'officialisation et passent en groupe A une fois officialisés. L'éditeur choisit ensuite les candidats des vidéos (`dans_le_panel`, à `non` pour tous en attendant).
   **Traité**, avec l'accord explicite de l'éditeur pour les fichiers protégés : `sources_a_surveiller.md` (règles 6 et 8, groupes A et D), `CLAUDE.md` (Neutralité), `prompts/01_ingestion.md`, `db/migrations/002_suivi_programmes.sql`.

## Garde-fous à renforcer dans le schéma

3. **Niveau 3 non bloqué en base.** La règle « pas de position depuis un réseau social seul » n'existe que dans les prompts. Proposition : déclencheur refusant le passage à `verifie` d'une position dont la source a `niveau_fiabilite = 3`.

4. **Panel non contrôlé par le déclencheur vidéo.** `controle_affirmation()` vérifie le statut et la validité, pas que le candidat est `dans_le_panel`. Proposition : ajouter cette condition.

5. **Couverture surestimée.** `v_trous_de_couverture` compte comme couverte une position `verifie` périmée (`valide_jusqu_a` dépassé). Proposition : reprendre la condition de validité de `v_positions_publiables`.

6. **Vue publiable incomplète pour la génération.** `v_positions_publiables` n'expose ni le slug du candidat, ni le slug du thème, ni `niveau_fiabilite`. Le prompt 02 filtre par thème et cite la source : il serait plus sûr de filtrer sur `t.slug` que sur `libelle`. Proposition : ajouter `c.slug AS candidat_slug`, `t.slug AS theme_slug`, `s.niveau_fiabilite`.

## Mineur

7. `comptes_decouverts.md` est cité par le prompt 01 sans emplacement précis. Proposition : `rapports/comptes_decouverts.md`.
8. Le cadre électoral (Arcom, période de campagne officielle) reste à vérifier avant la première publication, comme noté dans la conversation de cadrage.
