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
