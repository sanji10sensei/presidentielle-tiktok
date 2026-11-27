# Tableau de validation

Interface prévue pour l'éditeur humain : c'est le seul endroit où une vidéo passe de `a_valider` à `valide`. Rien n'est encore développé ; ce fichier décrit le besoin.

## Écran 1 : vidéos à valider

Liste des vidéos au statut `a_valider` (table `videos`), triées de la plus ancienne à la plus récente.

Pour chaque vidéo :

- format, thème, durée estimée, date de création ;
- le script complet, phrase par phrase, dans l'ordre d'affichage ;
- en face de chaque phrase de type affirmation : le candidat, le `resume_neutre`, l'`extrait_court`, et la source liée (éditeur, date de publication, lien vers l'URL et vers l'archive), lus via `video_affirmations` → `positions` → `sources` ;
- l'ordre d'affichage tiré au hasard et le temps d'écran de chaque candidat (`duree_ecran_s`), pour contrôler l'équité ;
- l'aperçu vidéo, une fois le rendu disponible ;
- l'état de l'étiquette IA (`etiquette_ia`).

Actions :

- **Valider** : renseigne `statut = 'valide'`, `valide_par` et `valide_le`.
- **Rejeter** : renvoie la vidéo en `brouillon`, avec un motif obligatoire (consigné dans le rapport).

## Écran 2 : positions à vérifier

Liste des positions au statut `brouillon`, avec le verdict de la relecture automatique (`prompts/03_relecture.md`) et le texte de la source à côté.

Actions :

- **Vérifier** : `statut = 'verifie'`, `verifie_par`, `verifie_le` (la contrainte du schéma refuse un `verifie` sans relecteur ni date).
- **Contester** : `statut = 'conteste'`.
- **Remplacer** : crée la nouvelle position et renseigne `remplace_par` sur l'ancienne, passée en `remplace`.

## Écran 3 : équité et couverture

- Vue `v_equite_temps_ecran` : temps d'écran cumulé par candidat sur les vidéos publiées.
- Vue `v_trous_de_couverture` : cases candidat × thème sans position vérifiée, c'est-à-dire les vidéos qu'on ne peut pas encore publier.

## Contraintes

- Accès réservé à l'éditeur (authentification Supabase). La clé `service_role` ne doit jamais être exposée côté navigateur.
- Aucune action de publication depuis ce tableau : la publication est faite par `scripts/publier_tiktok.py`, qui ne traite que les vidéos au statut `valide`.
