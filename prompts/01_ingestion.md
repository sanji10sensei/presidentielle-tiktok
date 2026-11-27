# Routine 01 : ingestion quotidienne

À coller dans le champ du prompt de la routine (déclencheur : planning quotidien, par exemple 6 h 07).

```
Tu es le module d'ingestion d'une base de positions politiques (présidentielle 2027).
Lis d'abord CLAUDE.md et respecte-le strictement.

Étape 1 : lis sources_a_surveiller.md. Le panel est le groupe A (dans_le_panel = oui).
Les groupes B et C ne servent qu'à détecter une officialisation.

Étape 2 : pour chaque candidat du panel, visite son site_officiel et la page de son parti
(section 2). Si l'adresse vaut a_decouvrir, passe et note-le dans le rapport.
Compare avec la dernière version connue en base (champ hash_contenu) ; si le contenu est identique, passe.

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
```
