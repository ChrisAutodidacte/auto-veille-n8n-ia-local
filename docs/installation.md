# Guide d'installation

Ce guide part de zéro et suppose des bases en auto-hébergement (Docker, n8n).

## 1. Pré-requis

- **Docker** et **Docker Compose** (v2)
- ~8 Go de RAM disponibles (Ollama + le reste de la stack)
- Un compte **Gmail** pour la collecte des newsletters et l'envoi des emails

## 2. Configuration

```bash
git clone https://github.com/ChrisAutodidacte/auto-veille-n8n-ia-local.git
cd auto-veille-n8n-ia-local
cp .env.example .env
```

Éditez `.env` et renseignez au minimum :

| Variable | Conseil |
|---|---|
| `DB_PASSWORD` | un mot de passe fort |
| `FLASK_SECRET_KEY` | `python -c "import secrets; print(secrets.token_hex(32))"` |
| `SEARXNG_SECRET` | `openssl rand -hex 32` |

## 3. Lancement de la stack

```bash
docker compose up -d
docker compose ps        # tous les services doivent être "running"/"healthy"
```

Au **premier** démarrage, PostgreSQL exécute automatiquement [`sql/init.sql`](../sql/init.sql)
et crée toutes les tables de la veille.

## 4. Télécharger le modèle d'IA

```bash
docker exec veille_ollama ollama pull qwen2.5:1.5b
```

> Modèle léger par défaut. Ollama gère beaucoup d'autres modèles (Gemma 3, Llama 3,
> Mistral…) : selon votre machine et vos besoins d'analyse, vous pouvez `pull` un modèle
> plus gros (ex. `qwen2.5:3b`, `gemma3:4b`) et le sélectionner dans le workflow d'analyse.
> Voir le tableau machine/modèle dans le [README](../README.md#-choisir-son-modèle-dia-selon-sa-machine).

## 5. Importer les workflows dans n8n

1. Ouvrez **http://localhost:5678** et créez votre compte n8n local.
2. Pour chaque fichier de [`workflows/`](../workflows/) : menu **⋮ → Import from File**.
3. Importez d'abord les sous-workflows (`Sub-*`, `WF-*`) puis les workflows principaux
   (`Maitre de la Veille`, `Analyseur Veille Ollama`, `Rapport Veille du Matin`).

## 6. Configurer les credentials n8n

Les credentials **ne sont pas** inclus dans le dépôt (sécurité). À créer dans n8n :

- **Gmail** (OAuth2) — pour la lecture des newsletters et l'envoi des emails. Reliez-le
  aux nœuds Gmail (étiquetés « Gmail Bot » après import).
- **Ollama** — base URL `http://ollama:11434`. Reliez-le au nœud d'analyse.

> SearXNG ne nécessite aucun credential : les workflows l'appellent directement sur
> `http://searxng:8080/search?format=json`.

## 7. Configurer vos sources et abonnés

Ouvrez l'admin sur **http://localhost:8090** :

- **Sources** → ajoutez vos sources de veille (email/recherche/scraping) et leur config.
- **Thèmes** → ajustez les thèmes de newsletter.
- **Abonnés** → ajoutez des abonnés (ou laissez-les s'inscrire par email).

## 8. Activer la planification

Dans n8n, **activez** les workflows à déclencheur planifié (collecte nocturne, rapport
du matin). Vérifiez le fuseau horaire (`TZ` dans `.env`).

---

## Dépannage rapide

| Symptôme | Piste |
|---|---|
| L'admin affiche une erreur DB | Vérifiez `docker compose ps` : `postgres` doit être *healthy* |
| n8n ne joint pas Ollama | Base URL du credential = `http://ollama:11434` (nom de service, pas localhost) |
| SearXNG renvoie du HTML, pas du JSON | Vérifiez que `json` est bien dans `search.formats` de `searxng/settings.yml` |
| Ollama très lent | Modèle trop gros pour la RAM/CPU : restez sur `qwen2.5:1.5b` ou activez le GPU |
