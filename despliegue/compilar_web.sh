#!/usr/bin/env bash
# Paso "build" de Vercel: arma el .env y compila el panel admin en build/web.

set -euo pipefail
cd "$(dirname "$0")/.."

readonly CARPETA_FLUTTER="${FLUTTER_HOME:-$HOME/flutter}"

# 1. Credenciales de Supabase en el .env (ver preparar_env.sh).
bash despliegue/preparar_env.sh

# 2. Flutter en el PATH (el paso install ya lo descargo y corrio pub get).
if ! command -v flutter >/dev/null 2>&1; then
  if [[ ! -x "$CARPETA_FLUTTER/bin/flutter" ]]; then
    bash despliegue/instalar_flutter.sh
  fi
  export PATH="$CARPETA_FLUTTER/bin:$PATH"
fi

# 3. Compilacion.
flutter --suppress-analytics build web --release --no-wasm-dry-run

if [[ ! -f build/web/index.html ]]; then
  echo "ERROR: la compilación no generó build/web/index.html." >&2
  exit 1
fi
echo "Sitio listo en build/web."
