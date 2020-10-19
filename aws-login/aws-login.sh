#!/usr/bin/env sh

set -euo pipefail

usage() {
  cat >&2 <<EOF
$0

Options:
  [-p <profile>]: the aws profile to use
  [-u <username>]: username to authenticate with identity provider
  [-r <role_arn>]: aws role to use
  [-s <service_provider_id>]: service provider to authenticate with
  [-i <identity_provider_id>]: identity provider id
  [-S]: save the configuration for future use
  [-h]: show this help message
  [-f]: force reauthentication
  [-F]: do not force reauthentication

The node module "gsts" must be installed and available on your path
EOF

}

CONFIG_LOCATION="${HOME}/.config/aws-login"

[ -f "$CONFIG_LOCATION" ] && . "$CONFIG_LOCATION" 

# config file doesn't support changing these variables
# so reset them to default values incase they've been changed
CONFIG_LOCATION="${HOME}/.config/aws-login"
HELP=""
SAVE=""

while getopts 'p:u:r:s:i:hSfF' arg "$@"
do
  case "$arg" in
    p) PROFILE="$OPTARG" ;;
    u) USERNAME="$OPTARG" ;;
    r) ROLE_ARN="$OPTARG" ;;
    s) SP_ID="$OPTARG" ;;
    i) IDP_ID="$OPTARG" ;;
    f) FORCE="yes" ;;
    F) FORCE="" ;;
    h) HELP=yes ;;
    S) SAVE=yes ;;
    ?)
      usage
      exit 1
    ;;
  esac
done

if [ -n "$HELP" ]; then
  usage
  exit 0
fi

if [ -z "$PROFILE" ]; then
  read -p "AWS Profile: " PROFILE
fi
if [ -z "$USERNAME" ]; then
  read -p "Username: " USERNAME
fi
if [ -z "$ROLE_ARN" ]; then
  read -p "Role ARN: " ROLE_ARN
fi
if [ -z "$SP_ID" ]; then
  read -p "Service Provider ID: " SP_ID
fi
if [ -z "$IDP_ID" ]; then
  read -p "Identity Provider ID: " IDP_ID
fi

FORCE_STRING=""
if [ -n "$FORCE" ]; then
  FORCE_STRING="--force"
fi

gsts \
  --aws-role-arn "$ROLE_ARN" \
  --sp-id "$SP_ID" \
  --idp-id "$IDP_ID" \
  --username "$USERNAME" \
  --aws-profile "$PROFILE" \
  $FORCE_STRING

if [ "$?" -ne "0" ]; then
  usage
  exit 1
fi

if [ -n "$SAVE" ]; then

  cat > "$CONFIG_LOCATION" <<EOF
################
# aws-login.sh #
################

# aws profile to use
PROFILE="$PROFILE"
# username for login
USERNAME="$USERNAME"
# arn of the aws role to assume
ROLE_ARN="$ROLE_ARN"
# service provider id
SP_ID="$SP_ID"
# identity provider id
IDP_ID="$IDP_ID"
# set FORCE to a non-empty string to force reauthentication
FORCE="$FORCE"

EOF

fi

