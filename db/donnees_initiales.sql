-- Données initiales : thèmes et candidats, d'après sources_a_surveiller.md (27 novembre 2026)
--
-- À exécuter une seule fois, après l'installation de la base.
-- Personne n'est dans le panel des vidéos (dans_le_panel = FALSE) : c'est l'éditeur
-- qui le coche, candidat par candidat.
-- Les sites officiels restent dans sources_a_surveiller.md ; programme_url sera rempli
-- par la collecte une fois le programme trouvé.

INSERT INTO themes (slug, libelle) VALUES
    ('retraites',   'Retraites'),
    ('logement',    'Logement'),
    ('energie',     'Énergie'),
    ('fiscalite',   'Fiscalité'),
    ('immigration', 'Immigration')
ON CONFLICT (slug) DO NOTHING;

-- Groupe A : candidatures déclarées (collectées)
-- Groupe B : ambition annoncée ; groupe C : pressentis ; groupe D : non officialisées
-- (B, C et D : veille d'officialisation uniquement)
INSERT INTO candidats (slug, nom, parti, statut, date_declaration) VALUES
    ('arthaud', 'Nathalie Arthaud', 'Lutte ouvrière', 'declare', NULL),
    ('melenchon', 'Jean-Luc Mélenchon', 'La France insoumise', 'declare', NULL),
    ('roussel', 'Fabien Roussel', 'Parti communiste français', 'declare', NULL),
    ('glucksmann', 'Raphaël Glucksmann', 'Place publique', 'declare', NULL),
    ('zemmour', 'Éric Zemmour', 'Reconquête', 'declare', NULL),
    ('le-pen', 'Marine Le Pen', 'Rassemblement national', 'declare', NULL),
    ('de-villepin', 'Dominique de Villepin', 'La France humaniste', 'declare', '2026-11-20'),
    ('attal', 'Gabriel Attal', 'Renaissance', 'declare', NULL),
    ('philippe', 'Édouard Philippe', 'Horizons', 'declare', NULL),
    ('retailleau', 'Bruno Retailleau', 'Les Républicains', 'declare', NULL),
    ('lisnard', 'David Lisnard', 'Nouvelle Énergie', 'declare', NULL),
    ('dupont-aignan', 'Nicolas Dupont-Aignan', 'Debout la France', 'declare', NULL),
    ('philippot', 'Florian Philippot', 'Les Patriotes', 'declare', NULL),
    ('asselineau', 'François Asselineau', 'Union populaire républicaine', 'declare', NULL),
    ('labib', 'Selma Labib', 'NPA-Révolutionnaires', 'declare', NULL),
    ('markovic', 'Mira Markovic', 'Parti animaliste', 'declare', NULL),
    ('lassalle', 'Jean Lassalle', 'Résistons', 'declare', NULL),
    ('lalanne', 'Francis Lalanne', 'France Libre', 'declare', NULL),
    ('kazib', 'Anasse Kazib', 'Révolution permanente', 'declare', NULL),
    ('polony', 'Natacha Polony', 'Société civile (journaliste, essayiste)', 'declare', NULL),
    ('riner', 'Teddy Riner', 'Société civile (judoka)', 'declare', NULL),
    ('tondelier', 'Marine Tondelier', 'Les Écologistes', 'ambition_annoncee', NULL),
    ('batho', 'Delphine Batho', 'Génération écologie', 'ambition_annoncee', NULL),
    ('bouamrane', 'Karim Bouamrane', 'PS, maire de Saint-Ouen', 'ambition_annoncee', NULL),
    ('platret', 'Gilles Platret', 'ex-Les Républicains, maire de Chalon-sur-Saône', 'ambition_annoncee', NULL),
    ('becht', 'Olivier Becht', 'Apparenté Ensemble pour la République, député', 'ambition_annoncee', NULL),
    ('bertrand', 'Xavier Bertrand', NULL, 'pressenti', NULL),
    ('hollande', 'François Hollande', NULL, 'pressenti', NULL),
    ('breton', 'Thierry Breton', NULL, 'pressenti', NULL),
    ('borne', 'Élisabeth Borne', NULL, 'pressenti', NULL),
    ('le-maire', 'Bruno Le Maire', NULL, 'pressenti', NULL),
    ('lagarde', 'Christine Lagarde', NULL, 'pressenti', NULL),
    ('pigasse', 'Matthieu Pigasse', NULL, 'pressenti', NULL),
    ('egger', 'Clara Egger', 'Solution démocratique', 'declare_peu_visible', NULL),
    ('mikolajczak', 'Antoine Mikolajczak', 'Equinoxe', 'declare_peu_visible', NULL),
    ('branco', 'Juan Branco', 'Les Ruches', 'declare_peu_visible', NULL),
    ('billetdoux', 'Augustin Billetdoux', NULL, 'declare_peu_visible', NULL),
    ('cheve', 'Joël Chevé', 'La France adulte', 'declare_peu_visible', NULL),
    ('collovati', 'Christian Collovati', NULL, 'declare_peu_visible', NULL),
    ('durif', 'Sylvain Durif', NULL, 'declare_peu_visible', NULL),
    ('legendre', 'Jean-François Legendre', 'À nous maintenant', 'declare_peu_visible', NULL),
    ('mathieu', 'Benoît Mathieu', NULL, 'declare_peu_visible', NULL),
    ('mlekuz', 'Manolo Mlekuz', 'Trajectoire', 'declare_peu_visible', NULL),
    ('rohou', 'Erwan Rohou', 'Mouvement écologiste indépendant', 'declare_peu_visible', NULL)
ON CONFLICT (slug) DO NOTHING;
