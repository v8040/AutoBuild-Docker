#!/usr/bin/env bash
set -eu

REPO_URL="${REPO_URL:?set REPO_URL env}"
REPO_URL="${REPO_URL%/}"
SLUG="${REPO_URL#*://*/}"
RUNNER_NAME="${RUNNER_NAME:-runner-$(date +%s)}"
LABELS="${LABELS:-tcr-sync}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-/home/runner/_work}"

cd /home/runner

if [[ ! -f .runner ]]; then
  TOKEN=$(curl -fsSL -X POST \
    -H "Authorization: Bearer ${GH_PAT:?set GH_PAT env}" \
    -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/${SLUG}/actions/runners/registration-token" | jq -er .token)
  CONFIG_ARGS=(
    --unattended
    --url "${REPO_URL}"
    --token "${TOKEN}"
    --name "${RUNNER_NAME}"
    --labels "${LABELS}"
    --work "${RUNNER_WORKDIR}"
    --replace
    --disableupdate
  )
  ./config.sh "${CONFIG_ARGS[@]}"
fi

exec ./run.sh
