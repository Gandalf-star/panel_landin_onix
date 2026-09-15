#!/usr/bin/env bash
# Arma el .env del panel con las variables de entorno del despliegue.
#
# El .env no esta en el repositorio (esta en .gitignore), pero pubspec.yaml
# lo declara como asset y sin el la compilacion falla. En Vercel se escribe
# con las variables del proyecto (Settings -> Environment Variables); en el
# computador se usa el .env que ya existe.
#
# Nunca imprime valores: solo nombres de variables, para poder diagnosticar
# el log sin exponer credenciales.

set -euo pipefail
cd "$(dirname "$0")/.."

# Nombres aceptados, en orden de preferencia. Supabase llama «publishable key»
# a la nueva clave publica y la integracion de Vercel usa el prefijo
# NEXT_PUBLIC_.
readonly NOMBRES_URL=(SUPABASE_URL NEXT_PUBLIC_SUPABASE_URL)
readonly NOMBRES_CLAVE=(
  SUPABASE_ANON_KEY
  SUPABASE_PUBLISHABLE_KEY
  NEXT_PUBLIC_SUPABASE_ANON_KEY
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
)

# Quita espacios y comillas que suelen colarse al pegar el valor.
limpiar() {
  local valor="$1"
  valor="${valor#"${valor%%[![:space:]]*}"}"
  valor="${valor%"${valor##*[![:space:]]}"}"
  valor="${valor#\"}"; valor="${valor%\"}"
  valor="${valor#\'}"; valor="${valor%\'}"
  printf '%s' "$valor"
}

# Imprime el nombre de la primera variable definida (no vacia) de la lista.
primera_definida() {
  local nombre
  for nombre in "$@"; do
    if [[ -n "$(limpiar "${!nombre:-}")" ]]; then
      printf '%s' "$nombre"
      return 0
    fi
  done
}

# true si la clave es secreta (service_role o sb_secret_): nunca puede ir al
# navegador.
es_clave_secreta() {
  local clave="$1" carga
  [[ "$clave" == sb_secret_* ]] && return 0
  if [[ "$clave" == eyJ*.*.* ]]; then
    carga="$(cut -d. -f2 <<<"$clave" | tr '_-' '/+')"
    while (( ${#carga} % 4 )); do carga+="="; done
    base64 -d <<<"$carga" 2>/dev/null | grep -q '"role" *: *"service_role"' && return 0
  fi
  return 1
}

fallar() {
  echo "ERROR: $1" >&2
  echo >&2
  echo "Ambiente del despliegue: ${VERCEL_ENV:-no es Vercel}" >&2
  echo "Variables con SUPABASE en el nombre que llegaron al build:" >&2
  compgen -e | grep -i supabase | sed 's/^/  - /' >&2 || echo "  (ninguna)" >&2
  cat >&2 <<'AYUDA'

Como resolverlo en Vercel (proyecto del panel admin):
  1. Settings -> Environment Variables.
  2. Agrega dos variables (Key = nombre exacto, Value = valor del .env):
       SUPABASE_URL       https://TU-PROYECTO.supabase.co
       SUPABASE_ANON_KEY  la clave publica (anon o publishable)
  3. Marca los ambientes Production y Preview.
  4. Deployments -> ... -> Redeploy (las variables solo aplican a despliegues
     nuevos).
AYUDA
  exit 1
}

nombre_url="$(primera_definida "${NOMBRES_URL[@]}")"
nombre_clave="$(primera_definida "${NOMBRES_CLAVE[@]}")"

if [[ -z "$nombre_url" && -z "$nombre_clave" ]]; then
  if [[ -f .env ]]; then
    echo "Usando el .env que ya existe."
    exit 0
  fi
  fallar "no llegaron las credenciales de Supabase al build."
fi
[[ -n "$nombre_url" ]] || fallar "falta la URL del proyecto (SUPABASE_URL)."
[[ -n "$nombre_clave" ]] || fallar "falta la clave pública (SUPABASE_ANON_KEY)."

url="$(limpiar "${!nombre_url}")"
clave="$(limpiar "${!nombre_clave}")"

if [[ "$url" != https://* ]]; then
  if [[ "$clave" == https://* ]]; then
    fallar "los valores están intercambiados: $nombre_url tiene la clave y $nombre_clave tiene la URL."
  fi
  fallar "$nombre_url debe ser la URL del proyecto y empezar con https://."
fi
if es_clave_secreta "$clave"; then
  fallar "$nombre_clave es una clave secreta (service_role). Usa la clave pública: todo lo del .env llega al navegador."
fi

segundos="$(limpiar "${SEGUNDOS_SONDEO:-}")"
{
  printf 'SUPABASE_URL=%s\n' "$url"
  printf 'SUPABASE_ANON_KEY=%s\n' "$clave"
  if [[ -n "$segundos" ]]; then
    printf 'SEGUNDOS_SONDEO=%s\n' "$segundos"
  fi
} > .env

echo "Credenciales de Supabase listas ($nombre_url, $nombre_clave) para ${url#https://}."
