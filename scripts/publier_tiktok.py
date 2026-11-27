"""Publication sur TikTok d'une vidéo validée par l'éditeur.

Squelette : les fonctions sont vides et documentent leur rôle. Aucun appel à une
API externe n'est fait pour l'instant.

Voie prévue : l'API TikTok Content Posting, qui demande un audit de l'application
avant toute publication publique. En attendant, la vidéo rendue est publiée à la
main ou via un outil de planification, et ce script sert seulement à préparer les
métadonnées et à tracer la publication en base.

Règles :
- On ne publie que des vidéos au statut `valide`, avec `valide_par` et `valide_le`
  renseignés. Aucune exception, même pour le format « point du jour ».
- Le marquage « contenu généré par IA » de TikTok est activé dès que `etiquette_ia`
  est vrai.
- Aucune clé ni jeton dans le dépôt : ils viennent des secrets de l'environnement.
"""

from pathlib import Path


def charger_video_validee(video_id: int) -> dict:
    """Lit la vidéo et vérifie statut = 'valide', `valide_par` et `valide_le` non nuls.

    Lève une erreur dans tout autre cas.
    """
    raise NotImplementedError


def verifier_fichier_rendu(video_id: int) -> Path:
    """Vérifie que le fichier rendu existe dans out/ et correspond à la version validée du script."""
    raise NotImplementedError


def preparer_metadonnees(video: dict) -> dict:
    """Construit la description TikTok : sources (éditeur, date, URL) de chaque
    affirmation, mention de l'ordre tiré au sort, lien vers la règle de sélection
    du panel, et indicateur de contenu IA si `etiquette_ia` est vrai."""
    raise NotImplementedError


def envoyer(fichier: Path, metadonnees: dict) -> str:
    """Envoie la vidéo via l'API Content Posting et renvoie l'identifiant TikTok.

    Non implémenté tant que l'application n'a pas passé l'audit de TikTok.
    """
    raise NotImplementedError


def enregistrer_publication(video_id: int, id_tiktok: str) -> None:
    """Passe la vidéo en `publie` et renseigne `publie_le` et `id_tiktok`."""
    raise NotImplementedError


def publier(video_id: int) -> str:
    """Point d'entrée : contrôles, métadonnées, envoi, puis traçage en base."""
    raise NotImplementedError


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        sys.exit("usage : python scripts/publier_tiktok.py <video_id>")
    print(publier(int(sys.argv[1])))
