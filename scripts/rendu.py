"""Rendu d'une vidéo à partir de son script validé en base.

Squelette : les fonctions sont vides et documentent leur rôle. Aucun appel à une
API externe n'est fait pour l'instant (ni base, ni voix de synthèse, ni montage).

Chaîne prévue :
    vidéo en base -> affirmations et sources -> chronologie -> voix -> sous-titres
    -> assemblage sur un template -> fichier dans out/ (ignoré par git)

Règles :
- On ne rend que des vidéos au statut `a_valider` ou `valide` : jamais de rendu
  d'un brouillon dont les positions ne sont pas vérifiées.
- Aucun candidat n'est représenté par une voix ou un visage de synthèse : la voix
  off est celle de la chaîne, les candidats n'apparaissent que par des citations
  écrites (`extrait_court`) ou des extraits réels.
- Si `etiquette_ia` vaut vrai, la mention « Voix de synthèse » est incrustée à l'écran.
"""

from pathlib import Path

DOSSIER_SORTIE = Path("out")
DOSSIER_TEMPLATES = Path("video/templates")
DOSSIER_ASSETS = Path("video/assets")

STATUTS_RENDABLES = {"a_valider", "valide"}


def charger_video(video_id: int) -> dict:
    """Lit la ligne `videos` et vérifie que son statut est dans STATUTS_RENDABLES.

    Renvoie un dictionnaire avec le format, le thème, le script (JSON produit par
    prompts/02_generation_script.md) et `etiquette_ia`. Lève une erreur sinon.
    """
    raise NotImplementedError


def charger_affirmations(video_id: int) -> list[dict]:
    """Lit `video_affirmations` jointe à `positions` et `sources`.

    Renvoie les affirmations triées par `ordre_affichage`, avec pour chacune le
    candidat, l'extrait court et la source (éditeur, date, URL) à afficher à l'écran.
    """
    raise NotImplementedError


def construire_chronologie(script: dict, affirmations: list[dict]) -> list[dict]:
    """Calcule le début et la fin de chaque phrase à l'écran.

    Contrôle l'équité : l'écart de durée entre candidats ne doit pas dépasser le
    seuil fixé (à définir). Les durées obtenues alimentent `duree_ecran_s`.
    """
    raise NotImplementedError


def generer_voix(chronologie: list[dict]) -> Path:
    """Produit la piste audio de la voix off (voix de la chaîne, jamais celle d'un candidat).

    Le fournisseur de synthèse vocale reste à choisir ; aucune clé n'est écrite dans
    le dépôt (secrets de l'environnement uniquement).
    """
    raise NotImplementedError


def generer_sous_titres(chronologie: list[dict]) -> Path:
    """Écrit un fichier de sous-titres (SRT ou ASS) calé sur la chronologie."""
    raise NotImplementedError


def assembler(chronologie: list[dict], audio: Path, sous_titres: Path, etiquette_ia: bool) -> Path:
    """Assemble la vidéo verticale 1080 × 1920 sur un template de video/templates/.

    Outil prévu : FFmpeg, Remotion ou Creatomate (à arbitrer). Incruste la source
    de chaque affirmation et, si `etiquette_ia` est vrai, la mention IA.
    """
    raise NotImplementedError


def rendre(video_id: int) -> Path:
    """Point d'entrée : enchaîne les étapes et renvoie le chemin du fichier rendu dans out/."""
    raise NotImplementedError


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        sys.exit("usage : python scripts/rendu.py <video_id>")
    print(rendre(int(sys.argv[1])))
