# 🤖 Auto Veille n8n IA Local

> 🇬🇧 **Looking for the English version?** See the English repository: [local-ai-news-monitor-n8n](https://github.com/ChrisAutodidacte/local-ai-news-monitor-n8n)

> Une plateforme de **veille technologique automatisée**, 100 % auto-hébergée, qui collecte l'information, l'analyse avec une **IA locale (Ollama)**, et la redistribue sous forme de **rapport quotidien** et de **newsletters personnalisées** — sans aucune API payante ni donnée envoyée dans le cloud.

<p align="center">
  <img alt="n8n"        src="https://img.shields.io/badge/n8n-workflows-EA4B71?logo=n8n&logoColor=white">
  <img alt="Ollama"     src="https://img.shields.io/badge/Ollama-IA%20locale-000000?logo=ollama&logoColor=white">
  <img alt="PostgreSQL" src="https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white">
  <img alt="Flask"      src="https://img.shields.io/badge/Flask-admin-000000?logo=flask&logoColor=white">
  <img alt="Docker"     src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white">
  <img alt="Licence"    src="https://img.shields.io/badge/Licence-MIT-green">
</p>

---

## 🎬 Démonstration

> 📺 **Vidéo de présentation et d'installation** : _(lien à venir)_
>
> Préférez l'écrit ? Suivez le **[tutoriel d'installation pas à pas](docs/tutoriel-installation.md)**.

<!-- Remplacez par une capture réelle de l'interface admin une fois disponible -->
<!-- ![Aperçu du dashboard](docs/images/dashboard.png) -->

---

## 💡 Pourquoi ce projet ?

Faire de la veille manuellement, c'est chronophage : ouvrir des dizaines de newsletters, parcourir des sites, trier, résumer… Ce projet **automatise toute la chaîne** :

1. Il **collecte** automatiquement l'info (emails/newsletters, recherche web, scraping).
2. Une **IA qui tourne sur votre machine** (Ollama) lit chaque article, le **résume**, le **classe par thème** et en extrait les mots-clés.
3. Vous recevez chaque matin un **rapport de synthèse**, et vos abonnés reçoivent des **newsletters filtrées selon leurs centres d'intérêt**.

Le tout **sans clé d'API externe** et **sans qu'aucune donnée ne quitte votre serveur** — un vrai cas d'usage « souveraineté numérique ».

---

## 🏗️ Architecture

```
                          ┌─────────────────────────────────────────┐
                          │              n8n (workflows)             │
                          │                                          │
   📧 Newsletters  ─────► │  Collecte  ─►  File d'attente articles   │
   🔎 Recherche web ────► │  (email /      (table articles_veille)   │
   🌐 Scraping     ─────► │   search /            │                  │
                          │   scraping)           ▼                  │
                          │              🧠 Analyse Ollama (locale)  │
                          │              résumé · thème · mots-clés  │
                          │                       │                  │
                          │         ┌─────────────┴───────────────┐  │
                          │         ▼                             ▼  │
                          │  📊 Rapport du matin      📰 Newsletters  │
                          │     (email synthèse)         abonnés     │
                          └─────────────────────────────────────────┘
                                          │
                                          ▼
                          🐘 PostgreSQL  ◄──►  🛠️ Admin Flask
                          (articles, sources,   (dashboard, CRUD
                           abonnés, thèmes)      sources & abonnés)
```

Schéma détaillé et flux de données dans **[docs/architecture.md](docs/architecture.md)**.

---

## 🧰 Stack technique

| Brique | Rôle |
|---|---|
| **[n8n](https://n8n.io)** | Orchestration des workflows (collecte, analyse, envoi) |
| **[Ollama](https://ollama.com)** | IA locale d'analyse (`qwen2.5:1.5b` par défaut) |
| **[SearXNG](https://docs.searxng.org)** | Méta-moteur de recherche web, sans clé d'API |
| **PostgreSQL 16** | Stockage articles, sources, abonnés, envois |
| **Flask** | Interface d'administration web (port 8090) |
| **Docker Compose** | Orchestration de toute la stack en une commande |

---

## 🧠 Choisir son modèle d'IA selon sa machine

L'un des atouts du tout-Docker : **le projet tourne à l'identique sur un serveur Linux
ou un PC Windows** — même configuration, même fonctionnement. La **seule** variable,
c'est la puissance de votre machine, qui détermine le modèle Ollama utilisable et la
vitesse d'analyse. **Plus de RAM (et un GPU) = un modèle plus puissant et plus rapide.**

Ollama prend en charge de **nombreux modèles légers** — Qwen 2.5, **Gemma 3**, Llama 3,
Mistral… — et on peut **basculer de l'un à l'autre selon le besoin d'analyse** (un modèle
peut mieux résumer, un autre mieux classer). Ci-dessous des ordres de grandeur, à ajuster
à votre matériel :

| Machine | Taille de modèle conseillée | Qualité d'analyse | Vitesse |
|---|---|---|---|
| PC modeste / 8 Go RAM, sans GPU | ~1,5–2 B (ex. `qwen2.5:1.5b`, `gemma3:1b`) | correcte | lente sur gros volumes |
| PC confortable / 16 Go RAM | ~3–4 B (ex. `qwen2.5:3b`, `gemma3:4b`) | bonne | correcte |
| Serveur ou PC avec GPU | 7 B et plus (ex. `qwen2.5:7b`, `gemma3:12b`) | très bonne | rapide |

Changer de modèle se fait en une ligne : `docker exec veille_ollama ollama pull <modèle>`,
puis on sélectionne ce modèle dans le workflow « Analyseur Veille Ollama ». Rien d'autre
ne change : **le reste de la stack et toute la configuration restent strictement les mêmes.**

> Le projet est livré avec `qwen2.5:1.5b` par défaut (léger, tourne partout), mais c'est
> un simple point de départ : remplacez-le par le modèle qui convient à votre machine et
> à vos besoins.

> 💡 Sur serveur Linux avec carte NVIDIA, décommentez le bloc GPU du `docker-compose.yml`
> pour accélérer Ollama nettement. Sur Windows, l'accélération GPU passe par WSL2.

---

## 🚀 Démarrage rapide

> **Pré-requis** : Docker + Docker Compose installés. Connaissances de base en auto-hébergement recommandées.

```bash
# 1. Cloner le dépôt
git clone https://github.com/ChrisAutodidacte/auto-veille-n8n-ia-local.git
cd auto-veille-n8n-ia-local

# 2. Configurer l'environnement
cp .env.example .env
#   → éditez .env (mots de passe, clés secrètes)

# 3. Lancer toute la stack
docker compose up -d

# 4. Télécharger le modèle d'IA dans Ollama
docker exec veille_ollama ollama pull qwen2.5:1.5b
```

Ensuite :
- **n8n** → http://localhost:5678 (importez les workflows du dossier [`workflows/`](workflows/))
- **Admin** → http://localhost:8090

Guide d'installation complet, configuration des credentials Gmail et import des workflows : **[docs/installation.md](docs/installation.md)**.

---

## 🧠 Méthodologie : développement supervisé multi-modèles

Ce projet n'a pas été « généré par une IA » d'un bloc. Il a été développé selon un
processus que je supervise, en faisant **collaborer deux IA aux rôles distincts** —
une approche qui rapproche le développement assisté par IA d'un vrai travail d'équipe
avec relecture par les pairs.

**Le rôle « architecte » (modèle avancé, type Opus)**
- Sert de base de réflexion sur les fonctionnalités à mettre en place.
- Produit un **fichier de spécification** pensé pour être exécuté par un modèle plus
  léger : cadré, guidé, découpé en étapes claires.
- Maintient un **fichier de progression** mis à jour au fil de l'avancement.

**Le rôle « développeur » (modèle plus léger, type Sonnet)**
- Implémente **étape par étape**, en suivant la spec.
- À chaque étape terminée, un **récapitulatif** est renvoyé à la session architecte.

**La boucle de supervision**

```
   Architecte (Opus)              Développeur (Sonnet)
   ─────────────────              ────────────────────
   conçoit la spec      ───────►  implémente l'étape
   + fichier de suivi                     │
          ▲                               ▼
          │                        envoie le récap
   relit, valide,       ◄───────  de l'étape terminée
   corrige si besoin
          │
          └──────────►  étape suivante… (et on recommence)
```

Ces **allers-retours entre modèles différents** apportent, à chaque étape, un point de
vue distinct — et permettent de repérer des choses qu'un seul modèle, seul, aurait
laissé passer, garantissant une architecture robuste et sans angle mort avant même d'écrire la moindre ligne de code.


> 😄 **Anecdote** : à une étape, la session de développement (Sonnet) a repéré et
> corrigé d'elle-même un oubli que la session de supervision (Opus) n'avait pas
> anticipé. La preuve, par l'exemple, que faire dialoguer plusieurs modèles vaut mieux
> que de tout confier à un seul.

Le principe directeur reste le même : **spécifier → planifier → implémenter → valider**,
en gardant la main sur l'architecture et les décisions techniques.

---

## 🗺️ Feuille de route

- [x] **Niveau 1** — Collecte newsletters + analyse Ollama + rapport quotidien
- [x] **Interface admin** — Dashboard, gestion des sources et des abonnés
- [x] **Newsletters abonnés** — Inscription/désinscription par email en langage naturel
- [ ] **Niveau 2/3** — Collecte web (SearXNG) + scraping, en amélioration continue
- [ ] **Extraction de contenu** — JSON-LD / Readability / trafilatura pour réduire le bruit

---

## ⚠️ Note de sécurité

Ce dépôt est une **base de démarrage**. Avant toute mise en production :
- changez **toutes** les valeurs de `.env` (mots de passe, clés secrètes) ;
- ne committez jamais votre fichier `.env` (déjà protégé par `.gitignore`) ;
- les **credentials n8n** (Gmail, SMTP…) se configurent dans n8n après l'import — ils ne sont pas inclus dans ce dépôt.

---

## 📄 Licence

Distribué sous licence **MIT**. Voir [LICENSE](LICENSE). Réutilisation libre, crédit apprécié. 🙂

---

## 💼 Besoin d'aide pour déployer ou adapter cet outil ?

Ce projet a été conçu par **Chris Autodidacte** pour automatiser la veille stratégique sans dépendre d'abonnements cloud coûteux ni exposer ses données.

Vous êtes une entreprise, un indépendant ou une équipe et vous souhaitez :
* Déployer et configurer cette stack sur votre propre serveur ou infrastructure locale ?
* Adapter les sources de veille, les modèles Ollama et les flux n8n à votre secteur d'activité ?
* Former vos équipes à l'utilisation concrète de l'IA locale et de l'automatisation de processus ?

👉 **Découvrez mes solutions et prenons contact sur [chrisconseil.fr](https://chrisconseil.fr)**  
📧 Contact direct : [contact@chrisconseil.fr](mailto:contact@chrisconseil.fr)  
📺 Retrouvez mes vidéos dans les coulisses du développement sur YouTube : **[Chris Autodidacte](https://www.youtube.com/@ChrisAutodidacte)**

