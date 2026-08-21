#!/bin/bash

set -eou pipefail

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
readonly AGE_KEY_DIR="${HOME}/.config/sops/"
readonly AGE_KEY_FILE="${AGE_KEY_DIR}/keys.txt"
readonly SOPS_YAML_PATH="${ROOT_DIR}/.sops.yaml"
readonly SECRET_FILE="${ROOT_DIR}/confs/bootstrap/gitea-admin.enc.yml"

if ! command -v age >/dev/null 2>&1; then
  echo "installing age ..."
  sudo dnf install -y age
else
  echo "skipping age already installed."
fi

if [ ! -s "${AGE_KEY_FILE}" ]; then
  echo "ERROR: age private key not found at ${AGE_KEY_FILE}"
  echo "       The encrypted secret was created with a specific keypair."
  echo "       Place the matching private key at: ${AGE_KEY_FILE}"
  exit 1
fi
chmod 600 "${AGE_KEY_FILE}"

readonly AGE_PUBLIC_KEY="$(sed -n '/public/p' "${AGE_KEY_FILE}" | awk '{print $4}')"
if [ -z "${AGE_PUBLIC_KEY}" ]; then
  echo "ERROR: could not extract public key"
  exit 1
fi

echo "using age public key: ${AGE_PUBLIC_KEY}"

cat >"${SOPS_YAML_PATH}" <<EOF
creation_rules:
  - path_regex: confs/bootstrap/.*\.enc\.ya?ml\$
    encrypted_regex: '^(data|stringData)\$'
    age: ${AGE_PUBLIC_KEY} 
EOF
echo "wrote ${SOPS_YAML_PATH}"
