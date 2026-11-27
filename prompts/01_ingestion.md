# Routine 01 : ingestion quotidienne

À coller dans le champ du prompt de la routine (déclencheur : planning quotidien, par exemple 6 h 07).

```
Tu es le module d'ingestion d'une base de positions politiques (présidentielle 2027).
Lis d'abord CLAUDE.md et respecte-le strictement.

Étape 1 : lis sources_a_surveiller.md.
Périmètre de collecte : TOUS les candidats déclarés, groupes A et D, quel que soit leur
parti, leurs élus ou leur notoriété. La colonne dans_le_panel ne limite pas la collecte :
elle ne sert qu'à choisir, plus tard et par l'éditeur, les candidats des vidéos.
Les groupes B et C ne servent qu'à détecter une officialisation.

Étape 2 : pour chaque candidat déclaré, cherche son programme ou ses propositions
publiés : site_officiel, page de son parti (section 2), et à défaut une recherche
sur son nom limitée aux domaines de la section 8. Si rien n'est trouvé, passe et
note-le dans le rapport ("programme non trouvé"). Ne déduis jamais l'absence de
programme d'une seule page inaccessible.
Compare avec la dernière version connue en base (champ hash_contenu) ; si le contenu est identique, passe.
Applique exactement la même procédure à chaque candidat, dans l'ordre alphabétique
du slug : aucun candidat n'est traité plus en profondeur qu'un autre.

Étape 3 : pour tout contenu nouveau, extrais les positions sur ces seuls thèmes :
retraites, logement, energie, fiscalite, immigration.
Pour chaque position, produis un JSON : candidat, theme, resume_neutre (une phrase
factuelle sans adjectif), extrait_court (copie exacte de la source, 200 caractères
maximum), chiffres (si présents), url_source, date_publication, niveau_fiabilite.

Étape 4 : insère le résultat dans Supabase avec le statut "brouillon" uniquement.

Étape 5 : veille d'officialisation. Consulte les pages de presse de la section 3 et
les sources institutionnelles de la section 4. Si un candidat des groupes B ou C annonce
officiellement sa candidature, ne change rien dans le fichier : signale-le en tête du rapport.

Étape 6 (première exécution uniquement) : pour chaque site_officiel accessible, relève les
liens vers les comptes de réseaux sociaux et écris-les dans comptes_decouverts.md.

Étape 7 : écris rapports/rapport_run.md (pages traitées, positions ajoutées, anomalies).
Ajoute un tableau de suivi des programmes, un candidat déclaré par ligne :
slug | programme trouvé (oui/non) | URL | date de publication | nombre de positions
en brouillon par thème. Ce tableau sert à l'éditeur pour choisir le panel des vidéos ;
tu ne proposes aucun classement ni aucune sélection.
```
