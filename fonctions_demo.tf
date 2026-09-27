# ============================================================
#  Démo des fonctions Terraform les plus utiles
#  Ce fichier génère un fichier de référence des fonctions
# ============================================================

locals {
  # ── Fonctions sur les strings ─────────────────────────────
  demo_strings = {
    upper       = upper("hello")            # "HELLO"
    lower       = lower("WORLD")            # "world"
    title       = title("hello world")      # "Hello World"
    trim        = trim("  hello  ", " ")    # "hello"
    replace     = replace("hello-world", "-", "_")  # "hello_world"
    split       = split(",", "a,b,c")       # ["a","b","c"]
    join        = join("-", ["a","b","c"])  # "a-b-c"
    contains    = contains(["a","b"], "a")  # true
    substr      = substr("hello", 0, 3)     # "hel"
    length_str  = length("hello")           # 5
    format_str  = format("%.2f", 3.14159)   # "3.14"
  }

  # ── Fonctions sur les nombres ─────────────────────────────
  demo_numbers = {
    max_val  = max(1, 5, 3, 2)    # 5
    min_val  = min(1, 5, 3, 2)    # 1
    abs_val  = abs(-42)            # 42
    ceil_val = ceil(4.1)           # 5
    floor_v  = floor(4.9)          # 4
  }

  # ── Fonctions sur les listes ──────────────────────────────
  demo_lists = {
    length  = length(["a","b","c"])            # 3
    flatten = flatten([["a","b"],["c","d"]])   # ["a","b","c","d"]
    sort    = sort(["c","a","b"])              # ["a","b","c"]
    reverse = reverse(["a","b","c"])           # ["c","b","a"]
    distinct= distinct(["a","b","a","c"])      # ["a","b","c"]
    slice   = slice(["a","b","c","d"], 1, 3)  # ["b","c"]
    index   = index(["a","b","c"], "b")        # 1
    toset   = toset(["a","b","a"])             # {"a","b"}
  }

  # ── Fonctions sur les maps ────────────────────────────────
  demo_maps = {
    keys    = keys({a=1, b=2})      # ["a","b"]
    values  = values({a=1, b=2})    # [1,2]
    lookup  = lookup({a=1}, "a", 0) # 1
    merge   = merge({a=1},{b=2})    # {a=1,b=2}
    tomap   = tomap({a="1",b="2"})
  }

  # ── Fonctions sur les dates ───────────────────────────────
  demo_dates = {
    timestamp   = timestamp()                            # RFC3339
    format_date = formatdate("DD/MM/YYYY", timestamp())  # "01/01/2024"
    format_time = formatdate("HH:mm", timestamp())       # "12:00"
  }
}

resource "local_file" "reference_fonctions" {
  filename = "${path.module}/output/reference_fonctions.json"
  content  = jsonencode({
    strings = local.demo_strings
    numbers = local.demo_numbers
    lists   = local.demo_lists
    maps    = local.demo_maps
    dates   = local.demo_dates
  })
}
