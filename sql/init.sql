-- =============================================================================
--  Schéma de base de données — Auto Veille n8n IA Local
-- =============================================================================
--  Ce script crée toutes les tables nécessaires à la veille automatisée et à
--  l'interface d'administration Flask.
--
--  Il est monté dans /docker-entrypoint-initdb.d/ : PostgreSQL l'exécute
--  automatiquement au TOUT PREMIER démarrage du conteneur (quand le volume de
--  données est vide). Les tables n8n elles-mêmes sont créées par n8n au
--  démarrage ; elles cohabitent dans la même base sans interférence.
--
--  Ordre des créations = ordre des dépendances (clés étrangères).
-- =============================================================================

-- 1. Sources de veille (emails, recherches web, scraping) ----------------------
CREATE TABLE IF NOT EXISTS sources_veille (
  id              SERIAL PRIMARY KEY,
  nom             TEXT NOT NULL,
  type_source     TEXT NOT NULL,                 -- email | search | web_scraping
  profil_analyse  TEXT,                          -- administratif | editorial | technique | general
  actif           BOOLEAN NOT NULL DEFAULT true,
  config          JSONB NOT NULL DEFAULT '{}',   -- clés selon type_source (voir docs/architecture.md)
  theme           TEXT,                          -- thème newsletter rattaché (optionnel)
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- 2. Articles collectés puis analysés par Ollama ------------------------------
CREATE TABLE IF NOT EXISTS articles_veille (
  id              SERIAL PRIMARY KEY,
  source_id       INT REFERENCES sources_veille(id),
  source_nom      TEXT,
  profil_analyse  TEXT,
  email_id        TEXT,
  url_source      TEXT NOT NULL DEFAULT 'aucune',
  titre_brut      TEXT,
  texte_brut      TEXT,
  origine_texte   TEXT,    -- article_externe | lecture_directe | newsletter_seule
  statut          TEXT DEFAULT 'a_analyser',   -- a_analyser | analyse | erreur
  theme_principal TEXT,
  public_cible    TEXT,
  titre_article   TEXT,
  resume_court    TEXT,
  resume_long     TEXT,
  mots_cles       JSONB,
  erreur_detail   TEXT,
  date_collecte   TIMESTAMPTZ DEFAULT now(),
  date_analyse    TIMESTAMPTZ,
  CONSTRAINT uniq_article_veille UNIQUE (email_id, url_source)
);
CREATE INDEX IF NOT EXISTS idx_articles_veille_statut ON articles_veille(statut);

-- 3. Thèmes proposés à l'abonnement newsletter --------------------------------
CREATE TABLE IF NOT EXISTS newsletter_themes (
  id    SERIAL PRIMARY KEY,
  nom   TEXT NOT NULL UNIQUE,
  ordre INT DEFAULT 0
);

-- 4. Abonnés à la newsletter --------------------------------------------------
CREATE TABLE IF NOT EXISTS newsletter_abonnes (
  id                SERIAL PRIMARY KEY,
  prenom            TEXT NOT NULL,
  email             TEXT NOT NULL UNIQUE,
  themes            TEXT[] NOT NULL DEFAULT '{}',
  periodicite       TEXT NOT NULL DEFAULT 'quotidien',  -- quotidien | hebdomadaire | mensuel
  actif             BOOLEAN NOT NULL DEFAULT true,
  date_inscription  TIMESTAMPTZ DEFAULT now(),
  date_modification TIMESTAMPTZ DEFAULT now()
);

-- 5. Historique des envois (déduplication article ↔ abonné) -------------------
CREATE TABLE IF NOT EXISTS newsletter_envois (
  id          SERIAL PRIMARY KEY,
  abonne_id   INT NOT NULL REFERENCES newsletter_abonnes(id),
  article_id  INT NOT NULL REFERENCES articles_veille(id),
  date_envoi  TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT uniq_envoi UNIQUE (abonne_id, article_id)
);
CREATE INDEX IF NOT EXISTS idx_envois_abonne  ON newsletter_envois(abonne_id);
CREATE INDEX IF NOT EXISTS idx_envois_article ON newsletter_envois(article_id);

-- 6. File d'attente des newsletters à expédier --------------------------------
CREATE TABLE IF NOT EXISTS newsletter_queue (
  id            SERIAL PRIMARY KEY,
  abonne_id     INT NOT NULL REFERENCES newsletter_abonnes(id),
  sujet         TEXT NOT NULL,
  html          TEXT NOT NULL,
  statut        TEXT NOT NULL DEFAULT 'a_envoyer',  -- a_envoyer | envoye | erreur
  date_creation TIMESTAMPTZ DEFAULT now(),
  date_envoi    TIMESTAMPTZ,
  erreur_detail TEXT
);

-- 7. Commandes reçues par email (inscription, désinscription…) en langage naturel
CREATE TABLE IF NOT EXISTS newsletter_emails_commandes (
  id                  SERIAL PRIMARY KEY,
  email_expediteur    TEXT NOT NULL,
  sujet_original      TEXT,
  corps_original      TEXT NOT NULL,
  statut              TEXT NOT NULL DEFAULT 'recu',   -- recu | en_traitement | a_envoyer | traite | erreur
  action_detectee     TEXT,    -- inscription | desinscription | modification | suggestion | incompris
  reponse_texte       TEXT,
  erreur_detail       TEXT,
  date_reception      TIMESTAMPTZ DEFAULT now(),
  date_traitement     TIMESTAMPTZ,
  date_envoi_reponse  TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_commandes_statut ON newsletter_emails_commandes(statut);

-- 8. Suggestions de nouveaux thèmes faites par les abonnés ---------------------
CREATE TABLE IF NOT EXISTS newsletter_suggestions_themes (
  id              SERIAL PRIMARY KEY,
  theme_suggere   TEXT NOT NULL,
  demandeur_email TEXT,
  statut          TEXT DEFAULT 'en_attente',   -- en_attente | accepte | refuse
  date_suggestion TIMESTAMPTZ DEFAULT now()
);

-- 9. Quelques thèmes de démarrage (modifiables depuis l'admin) ----------------
INSERT INTO newsletter_themes (nom, ordre) VALUES
  ('Technique', 1),
  ('Éditorial', 2),
  ('Administratif', 3),
  ('Général', 4)
ON CONFLICT (nom) DO NOTHING;
