# Outputs avancés avec for expressions

output "configs_par_env" {
  description = "Config de chaque environnement"
  value = {
    for env, cfg in local.env_configs :
    env => {
      db_host   = cfg.db_host
      replicas  = cfg.replicas
      log_level = cfg.log_level
    }
  }
}

output "fichiers_generes" {
  description = "Tous les fichiers générés, groupés par type"
  value = {
    configs   = [for f in local_file.config_env    : f.filename]
    vendeurs  = [for f in local_file.rapport_vendeur: f.filename]
    manifests = [for f in local_file.deploy_manifest: f.filename]
  }
}

output "deploy_ids" {
  description = "IDs de déploiement par environnement"
  value = {
    for env in keys(local.env_configs) :
    env => random_id.deploy_id[env].hex
  }
}

output "prod_actif" {
  description = "La config prod a-t-elle été déployée ?"
  value       = var.environnement == "prod" ? "Oui" : "Non"
}
