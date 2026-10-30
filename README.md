# Tinwoof 🐾

**Swipez. Matchez. Promenez.** Tinwoof fait se rencontrer les chiens du quartier : on swipe les profils autour de soi, un like réciproque ouvre la discussion, et il ne reste qu'à choisir le parc.

Application web progressive (PWA) installable sur iPhone et Android, pensée mobile d'abord.

## Fonctionnalités

- **Découvrir** : un deck de cartes à swiper au doigt (ou avec les flèches du clavier). Les chiens sont triés du plus proche au plus lointain, dans le rayon choisi. Un like réciproque déclenche l'écran « C'est un match » et ouvre une conversation.
- **Autour de moi** : la grille des chiens à proximité, avec la distance de chacun et des filtres par sexe et par rayon.
- **Carte** : MapLibre GL avec les tuiles OpenStreetMap d'[OpenFreeMap](https://openfreemap.org) (gratuites et sans clé), des marqueurs photo, des clusters, une projection globe quand on dézoome et le suivi de position en direct. Les chiens de la zone visible se chargent à chaque déplacement.
- **Messages** : chat en temps réel (Turbo Streams et Action Cable), pastilles de non-lus dans la barre d'onglets et sur l'icône de l'app installée (Badging API).
- **Profils** : galerie photo à balayer, traits de caractère, mots doux, spot de balade sur une mini-carte avec lien d'itinéraire, et partage natif (Web Share API).

### Géolocalisation respectueuse

- Position obtenue par l'API Geolocation du navigateur, **sur consentement explicite**. L'état de la permission est suivi via l'API Permissions.
- Coordonnées **arrondies à environ 110 m** avant d'être enregistrées. La position d'un utilisateur n'est jamais affichée, elle sert seulement à calculer les distances.
- Mise à jour discrète seulement si l'utilisateur s'est déplacé d'au moins 250 m. Il peut effacer sa position à tout moment depuis son profil.
- Autocomplétion d'adresse et géocodage inverse via [Photon](https://photon.komoot.io) (OpenStreetMap), sans clé.

### Une vraie app

- Manifest web (icônes « maskable », raccourcis), installation en un tap, invite adaptée sur iOS.
- Service worker : assets en cache, photos en *stale-while-revalidate*, page hors connexion.
- Transitions de vue (Turbo 8), préchargement des liens au survol, retour haptique au swipe et au match.
- Mode sombre automatique, *safe areas* iPhone, hauteurs en `dvh` adaptées au clavier mobile.

## Stack

Rails 7.0 · Ruby 3.1.2 · PostgreSQL · Hotwire (Turbo 8 et Stimulus 3) · webpack · Devise · Geocoder · Active Storage (Cloudinary en option) · MapLibre GL 5.

## Démarrer

```bash
bundle install
nvm use            # Node 22 (voir .nvmrc)
yarn install
cp .env.example .env
bin/rails db:setup # crée la base, charge le schéma et les données de démo
bin/dev            # serveur Rails + build JS en mode watch
```

Ouvrez <http://localhost:3000> et connectez-vous avec **demo@tinwoof.app** / **tinwoof123**. Plusieurs chiens du voisinage ont déjà liké Pixel, le chien du compte démo : vos premiers likes déclenchent donc des matchs.

> Base existante ? Lancez `bin/rails db:migrate` : les migrations de 2026 convertissent l'âge et la taille en nombres, renomment `race` en `breed` et ajoutent les likes, la position et les accusés de lecture.

## Tests

```bash
bin/rails test
```

Ils couvrent les modèles (match mutuel, distances, arrondi des positions, non-lus) et les parcours principaux : swipe, carte GeoJSON, chat, droits d'accès et PWA.

## Production

- `CLOUDINARY_URL` pour stocker les photos, `REDISCLOUD_URL` pour Action Cable (voir `.env.example`).
- Les assets se compilent avec `bin/rails assets:precompile`, qui lance aussi `yarn build`.
- Panneau d'administration sur `/admin`, réservé aux comptes `admin`.
