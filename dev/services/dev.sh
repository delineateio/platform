#!/usr/bin/env bash
set -e

clear
SERVICE="${1:-customers}"
ROOT="$(git rev-parse --show-toplevel)"
PROFILE="dev"
REPO="${GCP_REGISTRY}/${GCP_PROJECT}"

echo
echo "service:  ${DETAIL}${SERVICE}${RESET}"
echo "env:      ${DETAIL}${PROFILE}${RESET}"
echo "registry: ${DETAIL}${REPO}${RESET}"
echo

kubectl config use-context "${PROFILE}"

# Runs skaffold once
cd "${ROOT}/dev/services/${SERVICE}"
skaffold run -v warn -p "${PROFILE}" --default-repo="${REPO}"