#!/usr/bin/env bash
set -e


###################################################################
# Script Name	: bootstrap.sh
# Description	: Bootstraps a new environment for GCP & Cloudflare
# Args          : $1 delineate.io environment
#               : $2 GCP Project ID
#               : $3 GCP Region
# Author       	: Jonathan Fenwick
# Email         : jonathan.fenwick@delineate.io
###################################################################

echo
[[ -z "$1" ]] && { echo "${WARN}Environment not provided${RESET}" ; exit 1; }
[[ -z "$2" ]] && { echo "${WARN}GCP Project not provided${RESET}" ; exit 1; }
[[ -z "$3" ]] && { echo "${WARN}GCP Region not provided${RESET}" ; exit 1; }

# Sets variables
ENV="${1}"
PROJECT="${2}"
REGION="${3}"
USER="infrastructure"
SERVICE_ACCOUNT="${USER}@${PROJECT}.iam.gserviceaccount.com"
KEY_FILE="$HOME/.gcloud/$ENV/key.json"

echo
echo "Env:      ${DETAIL}${ENV}${RESET}"
echo "Project:  ${DETAIL}${PROJECT}${RESET}"
echo "Region:   ${DETAIL}${REGION}${RESET}"
echo "Account:  ${DETAIL}${SERVICE_ACCOUNT}${RESET}"
echo "Key:      ${DETAIL}${KEY_FILE}${RESET}"
echo

# Changes config settings
gcloud config set project "${PROJECT}"
gcloud config set compute/region "${REGION}"

# ---------------------------------------------------------------------

# Creates the state bucket from terraform
echo "${START}Creating Terraform state bucket...${RESET}"
gsutil mb -c standard -b on -l "${REGION}" "gs://${PROJECT}-tf/"
echo "${COMPLETE}Terraform state bucket created${RESET}"
echo

# ---------------------------------------------------------------------

# Create the service account
echo "${START}Creating '${USER}' service account...${RESET}"
gcloud iam service-accounts create ${USER} \
    --display-name="Infrastructure automation service account" \
    --description="Service account used to provision infrastructure during CI/CD"
echo "${COMPLETE}Service account created${RESET}"
echo

# ---------------------------------------------------------------------

# Add the roles to the service account
echo "${START}Adding roles...${RESET}"
while read -r ROLE; do
    gcloud projects add-iam-policy-binding "${PROJECT}" \
        --member="serviceAccount:${SERVICE_ACCOUNT}" --role="${ROLE}"
        echo "Added to '${ROLE}'"
done <roles.txt
echo "${COMPLETE}Roles added${RESET}"
echo

# ---------------------------------------------------------------------

echo "${START}Removing default fw rules and network...${RESET}"
# Deletes the default firewall rules and network
gcloud compute firewall-rules delete default-allow-icmp \
                                     default-allow-internal \
                                     default-allow-rdp \
                                     default-allow-ssh \
                                     --quiet

gcloud compute networks delete default --quiet
echo "${COMPLETE}Default network removed${RESET}"
echo

# ---------------------------------------------------------------------

echo "${START}Creating Cloudflare secrets...${RESET}"

gcloud secrets create "cloudflare-token" \
                            --replication-policy "automatic" \
                            --data-file "secrets/.token"

gcloud secrets create "cloudflare-zone" \
                            --replication-policy "automatic" \
                            --data-file "secrets/.zone"

echo "${START}Cloudflare secrets created${RESET}"
echo

# ---------------------------------------------------------------------

# displays the key on the screen
echo "${START}Creating service account key...${RESET}"

# Creates the key
gcloud iam service-accounts keys create "$KEY_FILE" \
                                --iam-account "${SERVICE_ACCOUNT}"

echo "${START}Service account token created${RESET}"

# ---------------------------------------------------------------------
