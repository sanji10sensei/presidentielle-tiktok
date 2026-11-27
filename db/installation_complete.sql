-- Installation complète de la base, à coller en une fois dans l'éditeur SQL de Supabase.
-- Fichier assemblé à partir des fichiers ci-dessous, dans cet ordre ; ne pas le modifier à la main :
--   db/schema_presidentielle.sql
--   db/migrations/001_statuts_candidats.sql
--   db/migrations/002_suivi_programmes.sql
--   db/migrations/003_garde_fous.sql


-- ==================== db/schema_presidentielle.sql ====================

-- Schéma PostgreSQL (compatible Supabase) : base de positions présidentielle 2027
-- Principe : aucune affirmation publiée sans position vérifiée, elle-même rattachée à une source datée.

CREATE TYPE statut_candidat AS ENUM ('declare', 'declare_sous_condition', 'pressenti', 'retire');
CREATE TYPE type_source AS ENUM ('programme', 'site_campagne', 'interview', 'reseau_social', 'presse', 'institutionnel');
CREATE TYPE statut_position AS ENUM ('brouillon', 'verifie', 'conteste', 'remplace');
CREATE TYPE statut_video AS ENUM ('brouillon', 'a_valider', 'valide', 'programme', 'publie', 'retire');

-- 1. Candidats : le panel est défini par une règle publique, pas au cas par cas
CREATE TABLE candidats (
    id              SERIAL PRIMARY KEY,
    slug            TEXT UNIQUE NOT NULL,
    nom             TEXT NOT NULL,
    parti           TEXT,
    statut          statut_candidat NOT NULL,
    date_declaration DATE,
    dans_le_panel   BOOLEAN NOT NULL DEFAULT FALSE,
    regle_panel     TEXT,                 -- ex. « candidat déclaré d'une formation représentée au Parlement »
    maj_le          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Thèmes : liste fermée, avec hiérarchie (retraites > âge légal)
CREATE TABLE themes (
    id          SERIAL PRIMARY KEY,
    slug        TEXT UNIQUE NOT NULL,     -- retraites, logement, energie, fiscalite, immigration…
    libelle     TEXT NOT NULL,
    parent_id   INT REFERENCES themes(id)
);

-- 3. Sources : archivées et hachées pour pouvoir prouver ce qui était dit à une date donnée
CREATE TABLE sources (
    id              SERIAL PRIMARY KEY,
    url             TEXT NOT NULL,
    url_archive     TEXT,                 -- copie figée (archive.org ou stockage interne)
    type            type_source NOT NULL,
    editeur         TEXT NOT NULL,
    publiee_le      DATE NOT NULL,
    recuperee_le    TIMESTAMPTZ NOT NULL DEFAULT now(),
    hash_contenu    TEXT,
    niveau_fiabilite SMALLINT NOT NULL CHECK (niveau_fiabilite BETWEEN 1 AND 3),
        -- 1 = texte officiel du candidat, 2 = presse de référence, 3 = relais secondaire
    UNIQUE (url, hash_contenu)
);

-- 4. Positions : cœur de la base
CREATE TABLE positions (
    id              BIGSERIAL PRIMARY KEY,
    candidat_id     INT NOT NULL REFERENCES candidats(id),
    theme_id        INT NOT NULL REFERENCES themes(id),
    source_id       INT NOT NULL REFERENCES sources(id),   -- NOT NULL = pas de source, pas de position
    resume_neutre   TEXT NOT NULL,        -- reformulation factuelle, sans adjectif
    extrait_court   TEXT CHECK (char_length(extrait_court) <= 200),  -- citation brève, le reste via le lien
    chiffres        JSONB,                -- {"cout_mds_eur": 12, "horizon": "2030", "chiffrage_par": "candidat|tiers"}
    valide_depuis   DATE NOT NULL,
    valide_jusqu_a  DATE,
    statut          statut_position NOT NULL DEFAULT 'brouillon',
    remplace_par    BIGINT REFERENCES positions(id),       -- historique des changements de position
    verifie_par     TEXT,
    verifie_le      TIMESTAMPTZ,
    CHECK (statut <> 'verifie' OR (verifie_par IS NOT NULL AND verifie_le IS NOT NULL))
);
CREATE INDEX idx_positions_cand_theme ON positions (candidat_id, theme_id, statut);

-- 5. Vidéos et traçabilité de chaque affirmation
CREATE TABLE videos (
    id              BIGSERIAL PRIMARY KEY,
    format          TEXT NOT NULL,        -- point_du_jour | comparateur | chiffrage
    theme_id        INT REFERENCES themes(id),
    script          TEXT NOT NULL,
    statut          statut_video NOT NULL DEFAULT 'brouillon',
    etiquette_ia    BOOLEAN NOT NULL DEFAULT TRUE,   -- voix de synthèse ou visuels générés
    programme_le    TIMESTAMPTZ,
    publie_le       TIMESTAMPTZ,
    id_tiktok       TEXT,
    valide_par      TEXT,
    valide_le       TIMESTAMPTZ
);

CREATE TABLE video_affirmations (
    video_id        BIGINT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    position_id     BIGINT NOT NULL REFERENCES positions(id),
    ordre_affichage SMALLINT NOT NULL,    -- ordre tiré au hasard, conservé pour audit
    duree_ecran_s   NUMERIC(5,1),         -- sert au suivi du temps de parole
    PRIMARY KEY (video_id, position_id)
);

-- Garde-fou : une vidéo ne cite que des positions vérifiées et en cours de validité
CREATE FUNCTION controle_affirmation() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM positions
        WHERE id = NEW.position_id
          AND statut = 'verifie'
          AND (valide_jusqu_a IS NULL OR valide_jusqu_a >= CURRENT_DATE)
    ) THEN
        RAISE EXCEPTION 'Position % non vérifiée ou périmée', NEW.position_id;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_controle_affirmation
BEFORE INSERT OR UPDATE ON video_affirmations
FOR EACH ROW EXECUTE FUNCTION controle_affirmation();

-- 6. Vues utiles
-- Matrice candidat × thème : ce que le générateur de scripts a le droit de lire
CREATE VIEW v_positions_publiables AS
SELECT c.nom, t.libelle AS theme, p.resume_neutre, p.extrait_court, p.chiffres,
       s.url, s.editeur, s.publiee_le, p.id AS position_id
FROM positions p
JOIN candidats c ON c.id = p.candidat_id AND c.dans_le_panel
JOIN themes t ON t.id = p.theme_id
JOIN sources s ON s.id = p.source_id
WHERE p.statut = 'verifie'
  AND (p.valide_jusqu_a IS NULL OR p.valide_jusqu_a >= CURRENT_DATE);

-- Équité : temps d'écran cumulé par candidat sur les vidéos publiées
CREATE VIEW v_equite_temps_ecran AS
SELECT c.nom, COUNT(DISTINCT va.video_id) AS nb_videos, SUM(va.duree_ecran_s) AS secondes_ecran
FROM video_affirmations va
JOIN positions p ON p.id = va.position_id
JOIN candidats c ON c.id = p.candidat_id
JOIN videos v ON v.id = va.video_id AND v.statut = 'publie'
GROUP BY c.nom
ORDER BY secondes_ecran DESC;

-- Trous de couverture : cases candidat × thème sans position vérifiée
CREATE VIEW v_trous_de_couverture AS
SELECT c.nom, t.libelle AS theme
FROM candidats c CROSS JOIN themes t
WHERE c.dans_le_panel
  AND NOT EXISTS (
      SELECT 1 FROM positions p
      WHERE p.candidat_id = c.id AND p.theme_id = t.id AND p.statut = 'verifie'
  );

-- ==================== db/migrations/001_statuts_candidats.sql ====================

-- Migration 001 : aligne l'enum statut_candidat sur sources_a_surveiller.md
--
-- Le fichier de sources utilise les statuts `ambition_annoncee` (groupe B) et
-- `declare_peu_visible` (groupe D), absents de l'enum créé par
-- db/schema_presidentielle.sql : l'insertion de ces candidats échouait.
--
-- Les valeurs existantes (declare, declare_sous_condition, pressenti, retire) sont
-- conservées. Aucune ligne existante n'est modifiée.
--
-- À exécuter après db/schema_presidentielle.sql. Idempotent (IF NOT EXISTS).
-- PostgreSQL 12 ou plus (Supabase : 15) : ADD VALUE est accepté dans une transaction,
-- mais les nouvelles valeurs ne sont utilisables qu'après la validation de celle-ci.
-- Exécuter cette migration seule, avant toute insertion de candidats.

ALTER TYPE statut_candidat ADD VALUE IF NOT EXISTS 'ambition_annoncee' AFTER 'declare_sous_condition';
ALTER TYPE statut_candidat ADD VALUE IF NOT EXISTS 'declare_peu_visible' AFTER 'declare';

-- ==================== db/migrations/002_suivi_programmes.sql ====================

-- Migration 002 : sépare la collecte du panel des vidéos
--
-- Règle de l'éditeur (27 novembre 2026) : tout candidat officiellement déclaré
-- (groupe A) est collecté, sans lien avec ses élus au Parlement. Les candidatures
-- non officialisées (declare_peu_visible, groupe D) ne sont pas collectées. Le panel des
-- vidéos (`dans_le_panel`) est choisi ensuite par l'éditeur, à partir de ce qui a
-- été collecté.
--
-- Le schéma le permet déjà : `positions` ne dépend pas de `dans_le_panel`, seules
-- les vues de publication (v_positions_publiables, v_trous_de_couverture) le filtrent.
-- Cette migration ajoute le suivi du programme de chaque candidat, et une vue de
-- collecte qui couvre tous les candidats déclarés.
--
-- À exécuter après la migration 001.

ALTER TABLE candidats
    ADD COLUMN IF NOT EXISTS programme_url       TEXT,
    ADD COLUMN IF NOT EXISTS programme_publie_le DATE;

-- Tant que l'éditeur n'a pas tranché, personne n'est dans le panel par défaut
-- (valeur déjà FALSE dans le schéma) : on ne met rien à jour ici.

-- Suivi de la collecte : tous les candidats officiellement déclarés, dans ou hors du panel
CREATE OR REPLACE VIEW v_suivi_collecte AS
SELECT c.slug, c.nom, c.parti, c.statut, c.dans_le_panel,
       c.programme_url, c.programme_publie_le,
       t.slug AS theme,
       COUNT(p.id) FILTER (WHERE p.statut = 'brouillon') AS nb_brouillons,
       COUNT(p.id) FILTER (WHERE p.statut = 'verifie')   AS nb_verifiees
FROM candidats c
CROSS JOIN themes t
LEFT JOIN positions p ON p.candidat_id = c.id AND p.theme_id = t.id
WHERE c.statut IN ('declare', 'declare_sous_condition')
GROUP BY c.slug, c.nom, c.parti, c.statut, c.dans_le_panel,
         c.programme_url, c.programme_publie_le, t.slug
ORDER BY c.slug, t.slug;

-- ==================== db/migrations/003_garde_fous.sql ====================

-- Migration 003 : garde-fous inscrits dans la base
--
-- Reprend les points 3, 4 et 5 de rapports/propositions_2026-11-27.md :
--   a) une position ne peut pas être vérifiée si sa source est de niveau 3 (réseau social
--      ou relais secondaire) : la règle n'existait que dans les prompts ;
--   b) une vidéo ne peut citer que des candidats du panel choisi par l'éditeur ;
--   c) une position vérifiée mais périmée ne compte plus comme couverte.
--
-- À exécuter après les migrations 001 et 002. Rejouable (CREATE OR REPLACE,
-- DROP TRIGGER IF EXISTS). Aucune ligne existante n'est modifiée.

-- a) Pas de position vérifiée sur une source de niveau 3 ----------------------------
CREATE OR REPLACE FUNCTION controle_niveau_source() RETURNS trigger AS $$
BEGIN
    IF NEW.statut = 'verifie' AND EXISTS (
        SELECT 1 FROM sources WHERE id = NEW.source_id AND niveau_fiabilite = 3
    ) THEN
        RAISE EXCEPTION 'Position % : une source de niveau 3 ne suffit pas pour vérifier une position', NEW.id;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_controle_niveau_source ON positions;
CREATE TRIGGER trg_controle_niveau_source
BEFORE INSERT OR UPDATE OF statut, source_id ON positions
FOR EACH ROW EXECUTE FUNCTION controle_niveau_source();

-- Une source déjà rattachée à une position vérifiée ne peut pas être déclassée en niveau 3
-- sans que la position soit d'abord repassée en brouillon ou contestée.
CREATE OR REPLACE FUNCTION controle_declassement_source() RETURNS trigger AS $$
BEGIN
    IF NEW.niveau_fiabilite = 3 AND OLD.niveau_fiabilite <> 3 AND EXISTS (
        SELECT 1 FROM positions WHERE source_id = NEW.id AND statut = 'verifie'
    ) THEN
        RAISE EXCEPTION 'Source % : des positions vérifiées en dépendent, repassez-les d''abord en brouillon ou en contesté', NEW.id;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_controle_declassement_source ON sources;
CREATE TRIGGER trg_controle_declassement_source
BEFORE UPDATE OF niveau_fiabilite ON sources
FOR EACH ROW EXECUTE FUNCTION controle_declassement_source();

-- b) Une vidéo ne cite que des candidats du panel -----------------------------------
-- Remplace la fonction du schéma ; le déclencheur trg_controle_affirmation existant
-- l'utilise sans modification.
CREATE OR REPLACE FUNCTION controle_affirmation() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM positions p
        WHERE p.id = NEW.position_id
          AND p.statut = 'verifie'
          AND (p.valide_jusqu_a IS NULL OR p.valide_jusqu_a >= CURRENT_DATE)
    ) THEN
        RAISE EXCEPTION 'Position % non vérifiée ou périmée', NEW.position_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM positions p
        JOIN candidats c ON c.id = p.candidat_id
        WHERE p.id = NEW.position_id AND c.dans_le_panel
    ) THEN
        RAISE EXCEPTION 'Position % : le candidat n''est pas dans le panel des vidéos', NEW.position_id;
    END IF;

    RETURN NEW;
END $$ LANGUAGE plpgsql;

-- c) Couverture : seules les positions vérifiées et en cours de validité comptent ----
CREATE OR REPLACE VIEW v_trous_de_couverture AS
SELECT c.nom, t.libelle AS theme
FROM candidats c CROSS JOIN themes t
WHERE c.dans_le_panel
  AND NOT EXISTS (
      SELECT 1 FROM positions p
      WHERE p.candidat_id = c.id AND p.theme_id = t.id AND p.statut = 'verifie'
        AND (p.valide_jusqu_a IS NULL OR p.valide_jusqu_a >= CURRENT_DATE)
  );
