# 🤖 Auto Veille n8n IA Local

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

> 📺 **Vidéo de présentation** : _(lien à venir)_

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

## 🧠 Méthodologie : développement piloté, pas délégué

Ce projet a été conçu en **dirigeant l'IA**, pas en la laissant tout faire. La démarche d'ingénierie est documentée et versionnée dans [`docs/`](docs/) :

- **Specs** (`docs/specs/`) — la conception réfléchie en amont de chaque niveau.
- **Plans** (`docs/plans/`) — le découpage en étapes d'implémentation.

C'est un parti pris assumé : **spécifier → planifier → implémenter**, en gardant la main sur l'architecture et les décisions techniques.

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
