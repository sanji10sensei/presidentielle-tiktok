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
