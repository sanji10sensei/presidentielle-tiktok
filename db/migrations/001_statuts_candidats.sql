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
