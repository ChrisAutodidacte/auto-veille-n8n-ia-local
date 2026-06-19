# 📺 Tutoriel d'installation pas à pas

Ce tutoriel détaillé reprend, étape par étape, l'installation complète de la stack.
Il accompagne la [vidéo de présentation](../README.md) et s'adresse aussi bien aux
débutants qu'à ceux qui préfèrent un guide écrit très structuré.

> Pour la version condensée « pour les pressés », voir [installation.md](installation.md).

---

## Avant de commencer

### Ce dont vous avez besoin

- **Docker Desktop** (Windows/Mac) ou **Docker Engine + Compose** (Linux) installé et démarré.
- **~8 Go de RAM** disponibles (Ollama est gourmand).
- **~10 Go d'espace disque** (images Docker + modèle d'IA).
- Un **compte Gmail** dédié à la veille (pour lire les newsletters et envoyer les emails).
- Des bases en ligne de commande (ouvrir un terminal, taper une commande).

### Vérifier que Docker fonctionne

Ouvrez un terminal et tapez :

```bash
docker --version
docker compose version
docker ps
```

Les deux premières commandes doivent afficher une version. La troisième doit afficher
un tableau (vide, c'est normal). Si `docker ps` renvoie une erreur de connexion,
**Docker Desktop n'est pas démarré** : lancez-le et attendez l'icône verte.

---

## Étape 1 — Récupérer le projet

```bash
git clone https://github.com/ChrisAutodidacte/auto-veille-n8n-ia-local.git
cd auto-veille-n8n-ia-local
```

Vous êtes maintenant dans le dossier du projet. Listez les fichiers (`ls` ou `dir`)
pour vérifier que `docker-compose.yml`, `README.md` et les dossiers `admin/`,
`workflows/`, `sql/` sont bien présents.

---

## Étape 2 — Configurer vos secrets (`.env`)

Le projet ne contient **aucun mot de passe** : vous les définissez vous-même dans un
fichier `.env`. Copiez le modèle :

```bash
cp .env.example .env
```

Ouvrez `.env` dans un éditeur de texte et renseignez :

| Variable | À mettre | Comment générer |
|---|---|---|
| `DB_PASSWORD` | un mot de passe fort | au choix |
| `FLASK_SECRET_KEY` | une longue chaîne aléatoire | `python -c "import secrets; print(secrets.token_hex(32))"` |
| `SEARXNG_SECRET` | une longue chaîne aléatoire | `openssl rand -hex 32` |
| `TZ` | votre fuseau | ex. `Europe/Paris` |

> ⚠️ Le fichier `.env` ne doit **jamais** être partagé ni commité. Il est déjà ignoré
> par git (voir `.gitignore`).

---

## Étape 3 — Télécharger les images (recommandé avant le premier lancement)

```bash
docker compose pull
```

Cette commande télécharge les images de PostgreSQL, n8n, Ollama, SearXNG et Redis.
Selon votre connexion, comptez **5 à 10 minutes**. C'est normal, laissez tourner.

---

## Étape 4 — Lancer toute la stack

```bash
docker compose up -d
```

Le `-d` lance les conteneurs en arrière-plan. Vérifiez qu'ils démarrent bien :

```bash
docker compose ps
```

Vous devez voir **6 conteneurs** : `veille_postgres`, `veille_n8n`, `veille_ollama`,
`veille_searxng`, `veille_searxng_redis`, `veille_admin`. PostgreSQL doit passer en
statut `healthy` au bout de quelques secondes.

> 💡 Au tout premier démarrage, PostgreSQL crée automatiquement toutes les tables de
> la veille (script `sql/init.sql`). Vous n'avez rien à faire.

---

## Étape 5 — Installer le modèle d'IA dans Ollama

L'IA ne contient aucun modèle au départ. Téléchargez celui par défaut :

```bash
docker exec veille_ollama ollama pull qwen2.5:1.5b
```

Le téléchargement (~1 Go) prend 1 à 3 minutes. Pour vérifier :

```bash
docker exec veille_ollama ollama list
```

> Le modèle `qwen2.5:1.5b` est léger et rapide. Pour une meilleure qualité d'analyse,
> vous pouvez essayer `qwen2.5:3b` (plus lent, plus gourmand en RAM) et adapter le
> modèle dans le workflow « Analyseur Veille Ollama ».

---

## Étape 6 — Configurer n8n

1. Ouvrez **http://localhost:5678** dans votre navigateur.
2. Créez votre compte n8n local (email + mot de passe — c'est local, rien n'est envoyé en ligne).

### 6.1 — Importer les workflows

Pour chaque fichier du dossier `workflows/` : menu **⋮ (en haut à droite) → Import from File**.

Importez dans cet ordre pour éviter les références manquantes :
1. D'abord les sous-workflows : `Sub-*.json`, `WF-Newsletter-*.json`
2. Ensuite les principaux : `Maitre de la Veille`, `Analyseur Veille Ollama`, `Rapport Veille du Matin`

### 6.2 — Configurer les credentials (l'étape clé !)

Les identifiants ne sont **pas** fournis (sécurité). Créez-les dans n8n :

- **Gmail (OAuth2)** : suivez l'assistant n8n pour autoriser votre compte Gmail.
  Reliez ce credential à tous les nœuds Gmail (étiquetés « Gmail Bot » après import).
- **Ollama** : créez un credential Ollama avec l'URL de base :
  ```
  http://ollama:11434
  ```
  > ⚠️ **Erreur classique** : ne mettez PAS `localhost:11434`. Depuis n8n (dans Docker),
  > Ollama se joint par son **nom de service** : `ollama`.

> SearXNG ne demande **aucun** credential : les workflows l'appellent directement.

---

## Étape 7 — Configurer la veille via l'interface admin

Ouvrez **http://localhost:8090**. Vous arrivez sur le dashboard.

1. **Thèmes** → vérifiez/ajustez les thèmes de newsletter proposés.
2. **Sources** → ajoutez votre première source de veille :
   - **email** : un expéditeur de newsletter (champ `sender`) + un label Gmail.
   - **search** : une requête de recherche web (via SearXNG).
   - **web_scraping** : une URL de page à surveiller.
3. **Abonnés** → ajoutez-vous comme premier abonné pour tester la newsletter.

---

## Étape 8 — Premier test de bout en bout

1. Dans n8n, ouvrez le workflow **« Maitre de la Veille »** et cliquez sur
   **Execute Workflow** (déclenchement manuel).
2. Patientez : la collecte s'exécute, puis l'**Analyseur Ollama** traite les articles
   un par un.
3. Retournez sur l'admin (**http://localhost:8090**) → page **Articles** : vos premiers
   articles analysés (résumé, thème, mots-clés) doivent apparaître. 🎉

---

## Étape 9 — Activer l'automatisation

Une fois le test concluant, **activez** les workflows à déclencheur planifié dans n8n
(interrupteur « Active » en haut à droite de chaque workflow) :
- la **collecte** (nocturne),
- le **rapport du matin**,
- les **newsletters**.

Vérifiez que le fuseau horaire (`TZ` dans `.env`) correspond au vôtre pour que les
horaires de déclenchement soient justes.

---

## Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| `docker ps` : erreur de connexion | Docker Desktop éteint | Démarrez Docker Desktop |
| L'admin affiche une erreur de base | PostgreSQL pas prêt | `docker compose ps` → attendre `healthy` |
| n8n : « connection refused » vers Ollama | Mauvaise URL | Credential Ollama = `http://ollama:11434` |
| SearXNG renvoie du HTML au lieu de JSON | Format JSON désactivé | Vérifier `json` dans `search.formats` de `searxng/settings.yml`, puis `docker compose restart searxng` |
| Ollama très lent | Modèle trop lourd / pas de GPU | Restez sur `qwen2.5:1.5b` ou activez le GPU (voir `docker-compose.yml`) |
| Un workflow référence un nœud manquant | Import partiel | Réimporter les sous-workflows d'abord |

---

## Arrêter ou réinitialiser

```bash
docker compose stop      # arrête sans rien supprimer
docker compose down      # arrête et supprime les conteneurs (les données restent)
docker compose down -v   # ⚠️ supprime AUSSI les données (base, n8n, modèle Ollama)
```
