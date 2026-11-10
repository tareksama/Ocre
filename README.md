# Dofus Ocre – suivi de L'éternelle moisson (Dofus Touch)

Appli Android pour suivre ta progression dans la quête du Dofus Ocre : les 35 étapes
(monstres, boss, archimonstres, Kralamoure Géant), 637 âmes à cocher, recherche par nom
ou par zone, stats par zone, plusieurs personnages et sauvegarde par code.

## Installer l'appli sur ton téléphone

1. Ouvre la page **Releases** du dépôt depuis ton téléphone :
   https://github.com/tareksama/ocre/releases/tag/latest
2. Télécharge `dofus-ocre.apk` et ouvre-le.
3. Android te demandera d'autoriser l'installation depuis ton navigateur : accepte.

Chaque `push` sur `main` reconstruit l'APK automatiquement (onglet **Actions**) et
remplace la release `latest`. Les nouvelles versions s'installent par-dessus l'ancienne
sans effacer ta progression.

## Organisation

| Dossier | Contenu |
|---|---|
| `web/index.html` | L'appli elle-même (HTML/JS). Fonctionne aussi dans un navigateur. |
| `web/data.js` | Données : monstres des 35 étapes et leurs zones d'apparition. |
| `web/img/` | Images des monstres (WebP), issues de l'encyclopédie officielle Dofus Touch. |
| `android/` | Projet Android minimal qui affiche `web/index.html` en plein écran (WebView). |
| `.github/workflows/android.yml` | Construction de l'APK et publication de la release. |

Pour modifier l'appli, il suffit d'éditer `web/index.html` puis de pousser.

## Sauvegarde

La progression est enregistrée sur le téléphone. Dans **Réglages**, copie de temps en
temps ton code de sauvegarde : il permet de tout restaurer (même après une
désinstallation).

## Données

Images des monstres : encyclopédie officielle Dofus Touch (static.ankama.com), via [MinZe25/dofus-ocre-tracker](https://github.com/MinZe25/dofus-ocre-tracker). Les images manquantes sont chargées en direct depuis le site officiel quand le téléphone est connecté.
Sous-zones et coordonnées de la carte extraites des fichiers du jeu via [bot4dofus/Datafus](https://github.com/bot4dofus/Datafus).

Liste des étapes et images (version Dofus Touch) : outil de suivi [axiazi.fr](https://axiazi.fr/dofus-touch/leternelle-moisson-dofus-ocre/).

Ancienne liste issue des outils communautaires
[Mopolo/Eternelle-Moisson](https://github.com/Mopolo/Eternelle-Moisson) et
[Ryswick/ocredex](https://github.com/Ryswick/ocredex). Si une étape diffère de ce
qu'Otomaï demande sur Dofus Touch, utilise le **mode édition** de l'appli.

> Note : la clé de signature (`android/app/ocre.keystore`) est dans le dépôt pour que
> les mises à jour s'installent sans effacer les données. C'est suffisant pour un usage
> perso ; ne publie pas l'appli sur le Play Store avec cette clé.
