#!/usr/bin/env bash
# Reads .env from the project root and writes TanCast/Config/Secrets.swift.
# Run once after cloning: ./scripts/generate_secrets.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
ENV_FILE="$ROOT/.env"
OUT="$ROOT/TanCast/Config/Secrets.swift"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env not found. Copy .env.example → .env and fill in your keys."
  exit 1
fi

# Load .env (skip blank lines and comments)
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  export "$key=$value"
done < "$ENV_FILE"

: "${REVENUECAT_API_KEY:?REVENUECAT_API_KEY is not set in .env}"

mkdir -p "$(dirname "$OUT")"

cat > "$OUT" << SWIFT
// AUTO-GENERATED — do not edit. Run scripts/generate_secrets.sh to regenerate.
enum Secrets {
    static let revenueCatAPIKey = "$REVENUECAT_API_KEY"
}
SWIFT

echo "Secrets.swift written to TanCast/Config/"
