-- Migration 002 : sépare la collecte du panel des vidéos
--
-- Règle de l'éditeur (27 novembre 2026) : tout candidat déclaré ayant publié un
-- programme est collecté, sans lien avec ses élus au Parlement. Le panel des
-- vidéos (`dans_le_panel`) est choisi ensuite par l'éditeur, à partir de ce qui a
-- été collecté.
--
-- Le schéma le permet déjà : `positions` ne dépend pas de `dans_le_panel`, seules
-- les vues de publication (v_positions_publiables, v_trous_de_couverture) le filtrent.
-- Cette migration ajoute le suivi du programme de chaque candidat, et une vue de
-- collecte qui couvre tous les candidats déclarés.
--
-- À exécuter après la migration 001 (utilise la valeur declare_peu_visible).

ALTER TABLE candidats
    ADD COLUMN IF NOT EXISTS programme_url       TEXT,
    ADD COLUMN IF NOT EXISTS programme_publie_le DATE;

-- Tant que l'éditeur n'a pas tranché, personne n'est dans le panel par défaut
-- (valeur déjà FALSE dans le schéma) : on ne met rien à jour ici.

-- Suivi de la collecte : tous les candidats déclarés, dans ou hors du panel
CREATE OR REPLACE VIEW v_suivi_collecte AS
SELECT c.slug, c.nom, c.parti, c.statut, c.dans_le_panel,
       c.programme_url, c.programme_publie_le,
       t.slug AS theme,
       COUNT(p.id) FILTER (WHERE p.statut = 'brouillon') AS nb_brouillons,
       COUNT(p.id) FILTER (WHERE p.statut = 'verifie')   AS nb_verifiees
FROM candidats c
CROSS JOIN themes t
LEFT JOIN positions p ON p.candidat_id = c.id AND p.theme_id = t.id
WHERE c.statut IN ('declare', 'declare_sous_condition', 'declare_peu_visible')
GROUP BY c.slug, c.nom, c.parti, c.statut, c.dans_le_panel,
         c.programme_url, c.programme_publie_le, t.slug
ORDER BY c.slug, t.slug;
