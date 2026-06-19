# Architecture & fonctionnement

Ce document explique comment les briques s'assemblent et comment circulent les données.

## Principe central : séparation collecte / analyse

Les workflows de **collecte** n'appellent jamais l'IA. Ils se contentent de récupérer
le contenu brut et de l'insérer dans la table `articles_veille` avec le statut
`a_analyser`. Un workflow d'**analyse** dédié traite ensuite ces articles **un par un**
(batch de 1) en appelant Ollama. Cette sérialisation est garantie par construction :
elle évite de saturer l'IA locale et rend chaque étape indépendante et rejouable.

## Flux de données

```
Sources (sources_veille, actif = true)
        │
        ▼
[Collecte]  email (Gmail) · search (SearXNG) · web_scraping (HTTP)
        │   insertion ON CONFLICT DO NOTHING (anti-doublon)
        ▼
articles_veille  (statut = a_analyser)
        │
        ▼
[Analyse Ollama]  résumé court/long · thème principal · mots-clés · public cible
        │   statut → analyse  (ou erreur)
        ▼
        ├──► [Rapport du matin]   synthèse des dernières 24h → email
        └──► [Newsletters]        sélection par thème/abonné → newsletter_queue → envoi
```

## Les tables

| Table | Rôle |
|---|---|
| `sources_veille` | Sources surveillées + leur `config` JSONB (selon le type) |
| `articles_veille` | Articles collectés puis enrichis par l'IA |
| `newsletter_themes` | Thèmes proposés à l'abonnement |
| `newsletter_abonnes` | Abonnés, leurs thèmes et leur périodicité |
| `newsletter_envois` | Historique d'envoi (déduplication article ↔ abonné) |
| `newsletter_queue` | File des newsletters prêtes à expédier |
| `newsletter_emails_commandes` | Commandes reçues par email (inscription…) |
| `newsletter_suggestions_themes` | Suggestions de thèmes faites par les abonnés |

Schéma complet et commenté : [`sql/init.sql`](../sql/init.sql).

## Configuration d'une source (`sources_veille.config`)

Le contenu de `config` (JSONB) dépend du `type_source` :

| `type_source` | Clés attendues |
|---|---|
| `email` | `sender`, `gmail_label`, `priorites[]`, `ignore[]` |
| `search` | `search_query`, `max_results`, `priorites[]`, `ignore[]` |
| `web_scraping` | `url`, `motif_url`, `max`, `priorites[]`, `ignore[]` |

`priorites` et `ignore` servent au scoring : une source mal configurée n'interrompt
jamais la collecte (valeurs par défaut `[]`).

## Les conteneurs

| Conteneur | Image | Port | Réseau interne |
|---|---|---|---|
| `veille_postgres` | postgres:16-alpine | 5432 | `postgres` |
| `veille_n8n` | n8nio/n8n | 5678 | `n8n` |
| `veille_ollama` | ollama/ollama | 11434 | `ollama` |
| `veille_searxng` | searxng/searxng | 8080 | `searxng` |
| `veille_searxng_redis` | redis:7-alpine | — | `searxng-redis` |
| `veille_admin` | build `./admin` | 8090 | `veille_admin` |

Tous partagent le réseau Docker `veille_network`, donc ils se joignent par leur **nom
de service** (ex. n8n appelle Ollama sur `http://ollama:11434` et SearXNG sur
`http://searxng:8080`).
