-- Migration 004 : verrouillage de l'accès public (Supabase)
--
-- Supabase expose le schéma public par son API, avec une clé publique (« anon »)
-- destinée aux navigateurs. Sans cette migration, toute personne disposant de cette
-- clé pourrait lire ou modifier les tables et les vues.
--
-- Après cette migration :
--   - la sécurité ligne par ligne (RLS) est active sur toutes les tables, sans aucune
--     règle d'accès : les rôles publics (anon, authenticated) ne voient rien ;
--   - les vues s'exécutent avec les droits de la personne qui les lit (security_invoker),
--     et ne contournent donc plus cette protection ;
--   - les droits des rôles publics sont retirés sur les tables, vues, séquences et
--     fonctions du projet, y compris celles créées plus tard.
-- L'éditeur (tableau de bord Supabase) et la collecte (clé service_role ou connexion
-- directe, gardées en secret) ne sont pas concernés : ils contournent la RLS.
--
-- À exécuter après la migration 003. Rejouable.

ALTER TABLE candidats          ENABLE ROW LEVEL SECURITY;
ALTER TABLE themes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE sources            ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos             ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_affirmations ENABLE ROW LEVEL SECURITY;

ALTER VIEW v_positions_publiables SET (security_invoker = true);
ALTER VIEW v_equite_temps_ecran   SET (security_invoker = true);
ALTER VIEW v_trous_de_couverture  SET (security_invoker = true);
ALTER VIEW v_suivi_collecte       SET (security_invoker = true);

-- Les rôles anon et authenticated n'existent que sur Supabase : on ne retire leurs
-- droits que s'ils existent (le fichier reste exécutable sur un PostgreSQL ordinaire).
DO $$
DECLARE r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM %I', r);
            EXECUTE format('REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM %I', r);
            EXECUTE format('REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM %I', r);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES    FROM %I', r);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM %I', r);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM %I', r);
        END IF;
    END LOOP;
END $$;
