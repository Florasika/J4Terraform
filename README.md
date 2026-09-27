# 🏗️ Jour 4 / 10 — Terraform : Resources Avancées

> **Série : 10 Days of Terraform** · Jour 4/10  
> Concepts : for_each · count · for expressions · Fonctions · Conditions · Provider random

---

## 📁 Fichiers du projet

```
day-04-avance/
│
├── main.tf               ← for_each, count, conditions, random
├── variables.tf          ← Variables
├── outputs.tf            ← Outputs avec for expressions
├── fonctions_demo.tf     ← Référence des fonctions Terraform
├── output/               ← Fichiers générés
│   ├── envs/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── vendeurs/
│   └── rapport_consolide.md
└── README.md
```

---

## 🚀 ÉTAPE 1 — Préparer les fichiers

```bash
mkdir -p jour4-terraform/output
cd jour4-terraform/

# Copier les fichiers depuis le dépôt :
# main_j4.tf         → main.tf
# variables_j4.tf    → variables.tf
# outputs_j4.tf      → outputs.tf
# fonctions_demo.tf  → fonctions_demo.tf
```

---

## 🔑 ÉTAPE 2 — for_each : créer N resources depuis une map

```hcl
# for_each itère sur chaque clé/valeur de la map
# each.key   = la clé     ("dev", "staging", "prod")
# each.value = la valeur  (objet de config)

resource "local_file" "config_env" {
  for_each = local.env_configs   # map avec 3 entrées → 3 fichiers

  filename = "output/${each.key}/config.json"
  content  = jsonencode({
    env      = each.key
    replicas = each.value.replicas
    db_host  = each.value.db_host
  })
}

# Dans le state, chaque ressource a une clé :
# local_file.config_env["dev"]
# local_file.config_env["staging"]
# local_file.config_env["prod"]
```

---

## 🔑 ÉTAPE 3 — count : créer N resources depuis un nombre

```hcl
locals {
  vendeurs = ["Alice", "Karim", "Lucie", "Thomas", "Nadia"]
}

resource "local_file" "rapport_vendeur" {
  count = length(local.vendeurs)   # 5 → crée 5 fichiers

  filename = "output/vendeurs/${local.vendeurs[count.index]}.md"
  content  = "Rang : ${count.index + 1}"
}

# Dans le state :
# local_file.rapport_vendeur[0]  → Alice
# local_file.rapport_vendeur[1]  → Karim
# ...
```

**Différence for_each vs count :**
- `count` → accès par index (fragile si on retire un élément)
- `for_each` → accès par clé (stable, recommandé)

---

## 🔑 ÉTAPE 4 — for expressions : transformer des collections

```hcl
# Transformer une map en une autre map
output "configs" {
  value = {
    for env, cfg in local.env_configs :
    env => cfg.db_host     # clé => valeur transformée
  }
}
# → { dev = "dev-db.internal", prod = "prod-db.internal" }

# Filtrer avec if
output "envs_actifs" {
  value = [
    for env, cfg in local.env_configs :
    env
    if cfg.actif == true   # filtre
  ]
}
# → ["dev", "staging", "prod"]

# Transformer une liste
output "vendeurs_majuscules" {
  value = [for v in local.vendeurs : upper(v)]
}
# → ["ALICE", "KARIM", "LUCIE", "THOMAS", "NADIA"]
```

---

## 🔑 ÉTAPE 5 — Condition ternaire

```hcl
# condition ? valeur_si_vrai : valeur_si_faux

# count conditionnel — resource créée seulement en prod
resource "local_file" "prod_only" {
  count    = var.environnement == "prod" ? 1 : 0
  filename = "output/prod_only.json"
  content  = "Fichier prod uniquement"
}

# Valeur conditionnelle dans une resource
locals {
  timeout = var.environnement == "prod" ? 60 : 30
  db_url  = var.environnement == "prod" ? "prod-db:5432" : "localhost:5432"
}
```

---

## 🔑 ÉTAPE 6 — Provider random

```hcl
terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

# Générer un ID unique par environnement
resource "random_id" "deploy_id" {
  for_each    = local.env_configs
  byte_length = 4   # 4 bytes → 8 caractères hex
}

# Utiliser dans une resource
resource "local_file" "manifest" {
  for_each = local.env_configs
  filename = "output/${each.key}/deploy.json"
  content  = jsonencode({
    deploy_id = random_id.deploy_id[each.key].hex      # "a1b2c3d4"
    image_tag = "v1.0.0-${random_id.deploy_id[each.key].hex}"
  })
}
```

---

## 🔑 ÉTAPE 7 — Fonctions Terraform essentielles

```hcl
# Strings
upper("hello")              # "HELLO"
lower("WORLD")              # "world"
replace("a-b", "-", "_")   # "a_b"
join("-", ["a","b","c"])    # "a-b-c"
split(",", "a,b,c")         # ["a","b","c"]
format("v%.1f", 1.0)        # "v1.0"

# Listes
length(["a","b","c"])       # 3
flatten([["a"],["b","c"]])  # ["a","b","c"]
sort(["c","a","b"])         # ["a","b","c"]
distinct(["a","b","a"])     # ["a","b"]

# Maps
keys({a=1, b=2})            # ["a","b"]
values({a=1, b=2})          # [1,2]
lookup({a=1}, "a", 0)       # 1 (0 si clé absente)
merge({a=1},{b=2})          # {a=1,b=2}

# Dates
timestamp()                 # "2024-01-01T12:00:00Z"
formatdate("DD/MM/YYYY", timestamp())  # "01/01/2024"

# Encodage
jsonencode({a=1})           # '{"a":1}'
base64encode("hello")       # "aGVsbG8="
```

---

## 🚀 ÉTAPE 8 — Initialiser et appliquer

```bash
terraform init
# → télécharge les providers local ET random

terraform plan
# Résultat :
# local_file.config_env["dev"]        will be created
# local_file.config_env["staging"]    will be created
# local_file.config_env["prod"]       will be created
# local_file.rapport_vendeur[0]       will be created
# ...
# random_id.deploy_id["dev"]          will be created
# ...
# Plan: 15 to add, 0 to change, 0 to destroy.

terraform apply -auto-approve
```

---

## 🚀 ÉTAPE 9 — Vérifier les outputs

```bash
terraform output configs_par_env
terraform output deploy_ids
terraform output fichiers_generes

# Voir le fichier de référence des fonctions
cat output/reference_fonctions.json | python3 -m json.tool

# Voir un manifest de déploiement
cat output/envs/prod/deploy.json
```

---

## 🚀 ÉTAPE 10 — Tester avec environnement=prod

```bash
# Avec prod → le fichier prod_only est créé
terraform apply -var="environnement=prod" -auto-approve
ls output/prod_only_config.json   # existe ✓

# Avec dev → le fichier prod_only n'est pas créé
terraform apply -var="environnement=dev" -auto-approve
ls output/prod_only_config.json   # n'existe pas ✓
```

---

## 💡 for_each vs count — quand utiliser quoi ?

| Situation | Recommandation |
|-----------|----------------|
| Liste d'éléments nommés (envs, régions) | `for_each` |
| Simple répétition numérique | `count` |
| Ajouter/retirer un élément | `for_each` (pas de shift d'index) |
| Activer/désactiver une resource | `count = condition ? 1 : 0` |



---

⭐ **Si ce projet t'aide, mets une étoile !**
