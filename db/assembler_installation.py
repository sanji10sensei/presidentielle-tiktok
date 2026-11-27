"""Régénère db/installation_complete.sql à partir du schéma et des migrations.

Usage, depuis la racine du dépôt : python3 db/assembler_installation.py
À relancer après chaque nouvelle migration.
"""
from pathlib import Path

RACINE = Path(__file__).resolve().parent
fichiers = [RACINE / "schema_presidentielle.sql"] + sorted((RACINE / "migrations").glob("[0-9][0-9][0-9]_*.sql"))
noms = [str(f.relative_to(RACINE.parent)) for f in fichiers]

texte = (
    "-- Installation complète de la base, à coller en une fois dans l'éditeur SQL de Supabase.\n"
    "-- Fichier généré par db/assembler_installation.py ; ne pas le modifier à la main.\n"
    "-- Contenu, dans cet ordre :\n"
    + "".join(f"--   {n}\n" for n in noms)
    + "\n"
)
for f, n in zip(fichiers, noms):
    texte += f"\n-- ==================== {n} ====================\n\n" + f.read_text(encoding="utf-8")

(RACINE / "installation_complete.sql").write_text(texte, encoding="utf-8")
print(f"db/installation_complete.sql : {len(fichiers)} fichiers assemblés")
