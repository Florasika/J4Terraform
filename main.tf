# ============================================================
#  JOUR 4 / 10 — Terraform : Providers & Resources avancées
#  Concepts : for_each · count · dynamic · fonctions · conditions
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local  = { source = "hashicorp/local",  version = "~> 2.4" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "local"  {}
provider "random" {}

# ── LOCALS : données et transformations ──────────────────────
locals {
  # Environnements à déployer
  environnements = toset(["dev", "staging", "prod"])

  # Config par environnement (objet complexe)
  env_configs = {
    dev = {
      replicas    = 1
      log_level   = "DEBUG"
      db_host     = "dev-db.internal"
      actif       = true
      tags        = ["dev", "test"]
    }
    staging = {
      replicas    = 2
      log_level   = "INFO"
      db_host     = "staging-db.internal"
      actif       = true
      tags        = ["staging", "pre-prod"]
    }
    prod = {
      replicas    = 3
      log_level   = "WARNING"
      db_host     = "prod-db.internal"
      actif       = true
      tags        = ["prod", "live", "critical"]
    }
  }

  # Vendeurs pour démontrer count
  vendeurs = ["Alice", "Karim", "Lucie", "Thomas", "Nadia"]
}

# ── FOR_EACH : créer N resources depuis une map/set ──────────
# for_each itère sur chaque élément et crée une resource par entrée
# each.key = la clé (nom env), each.value = la valeur (config)
resource "local_file" "config_env" {
  for_each = local.env_configs

  filename = "${path.module}/output/envs/${each.key}/config.json"
  content  = jsonencode({
    environnement = each.key
    replicas      = each.value.replicas
    log_level     = each.value.log_level
    db_host       = each.value.db_host
    tags          = each.value.tags

    # Fonctions Terraform intégrées
    nom_upper     = upper(each.key)           # "DEV", "PROD"...
    nom_lower     = lower(each.key)           # "dev", "prod"...
    tags_jointes  = join(", ", each.value.tags) # "dev, test"
    nb_tags       = length(each.value.tags)
    timestamp     = formatdate("DD/MM/YYYY", timestamp())
  })
  file_permission = "0644"
}

# ── COUNT : créer N resources depuis un nombre ────────────────
# count.index = l'indice (0, 1, 2...)
resource "local_file" "rapport_vendeur" {
  count = length(local.vendeurs)

  filename = "${path.module}/output/vendeurs/${local.vendeurs[count.index]}.md"
  content  = <<-EOT
    # Rapport — ${local.vendeurs[count.index]}

    **Rang :** ${count.index + 1} / ${length(local.vendeurs)}
    **Objectif mensuel :** ${(count.index + 1) * 10000} €

    Généré par Terraform (count.index = ${count.index})
  EOT
}

# ── DYNAMIC BLOCK : construire des blocs répétitifs ──────────
# Utilisé ici pour créer un rapport consolidé avec plusieurs sections
resource "local_file" "rapport_consolide" {
  filename = "${path.module}/output/rapport_consolide.md"

  content = join("\n\n", [
    "# Rapport Consolidé — ${var.nom_projet}",
    "Généré le : ${formatdate("DD/MM/YYYY", timestamp())}",
    "---",

    # for expression : transformer une liste en string
    join("\n", [
      for env, cfg in local.env_configs :
      "## ${upper(env)}\n- Replicas: ${cfg.replicas}\n- Log: ${cfg.log_level}\n- DB: ${cfg.db_host}"
    ]),

    "---",
    "## Équipe vendeurs",
    join("\n", [
      for i, v in local.vendeurs :
      "${i + 1}. ${v} — objectif: ${(i + 1) * 10000}€"
    ]),
  ])
}

# ── CONDITION (ternaire) : valeur selon une condition ─────────
# condition ? valeur_si_vrai : valeur_si_faux
resource "local_file" "config_prod_only" {
  # count = condition ternaire — crée 1 resource si prod, 0 sinon
  count = var.environnement == "prod" ? 1 : 0

  filename = "${path.module}/output/prod_only_config.json"
  content  = jsonencode({
    message  = "Ce fichier existe seulement en production"
    replicas = local.env_configs["prod"].replicas
    critical = true
  })
}

# ── RANDOM : générer des valeurs aléatoires ──────────────────
resource "random_id" "deploy_id" {
  for_each    = local.env_configs
  byte_length = 4   # 4 bytes = 8 caractères hex
}

# Utiliser les random IDs dans un fichier de déploiement
resource "local_file" "deploy_manifest" {
  for_each = local.env_configs

  filename = "${path.module}/output/envs/${each.key}/deploy.json"
  content  = jsonencode({
    environnement = each.key
    deploy_id     = random_id.deploy_id[each.key].hex
    deploy_b64    = random_id.deploy_id[each.key].b64_std
    replicas      = each.value.replicas
    image_tag     = "v${var.version_app}-${random_id.deploy_id[each.key].hex}"
  })
}
