 #!/bin/bash

DIR=$(pwd)
DATAFILE="$DIR/$1"


# These all variables should be created on your config file before you run script.
# <ENVIRONMENT> <BUCKET> <DEPLOYMENT> <PROJECT> <CREDENTIALS> etc..

if [ ! -f "$DATAFILE" ]; then
  echo "setenv: Configuration file not found: $DATAFILE"
  return 1
fi

# wget --quiet -O "$PWD/common_configuration.tfvars"\
#   "https://raw.githubusercontent.com/florinen/vsphere-env/master/consul_backend.tfvars"

BACKEND=$(sed -nr 's/^backend\s*=\s*"([^"]*)".*$/\1/p'                       "$DATAFILE")
BUCKET=$(sed -nr 's/^bucket\s*=\s*"([^"]*)".*$/\1/p'                         "$DATAFILE")
#KEY=$(sed -nr 's/^key\s*=\s*"([^"]*)".*$/\1/p'                               "$DATAFILE")
REGION=$(sed -nr 's/^region\s*=\s*"([^"]*)".*$/\1/p'                         "$DATAFILE")
ENVIRONMENT=$(sed -nr 's/^deployment_environment\s*=\s*"([^"]*)".*$/\1/p'    "$DATAFILE")
#DEPLOYMENT=$(sed -nr 's/^deployment_name\s*=\s*"([^"]*)".*$/\1/p'            "$DATAFILE")
PROJECT=$(sed -nr 's/^provider_name\s*=\s*"([^"]*)".*$/\1/p'                 "$DATAFILE")
STATEFILE=$(sed -nr 's/^state_file_name\s*=\s*"([^"]*)".*$/\1/p'             "$DATAFILE")
#CREDENTIALS=$(sed -nr 's/^credentials\s*=\s*"([^"]*)".*$/\1/p'               "$DATAFILE")



if [ -z "$BACKEND" ]
then
    echo "setenv: 'backend' variable not set in configuration file."
    return 1
fi

if [ -z "$BUCKET" ]
then
    echo "setenv: 'bucket' variable not set in configuration file."
    return 1
fi

# if [ -z "$KEY" ]
# then
#   echo "setenv: 'key' variable not set in configuration file."
#   return 1
# fi

if [ -z "$REGION" ]
then
  echo "setenv: 'region' variable not set in configuration file."
  return 1
fi

if [ -z "$PROJECT" ]
then
    echo "setenv: 'provider_name' variable not set in configuration file."
    return 1
fi

if [ -z "$ENVIRONMENT" ]
then
    echo "setenv: 'deployment_environment' variable not set in configuration file."
    return 1
fi

# if [ -z "$DEPLOYMENT" ]
# then
#     echo "setenv: 'deployment_name' variable not set in configuration file."
#     return 1
# fi
if [ -z "$STATEFILE" ]
then
    echo "setenv: 'state_file_name' variable not set in configuration file."
    return 1
fi
# if [ -z "$CREDENTIALS" ]
# then
#     echo "setenv: 'credentials' file not set in configuration file."
#     return 1
# fi

cat << EOF > "$DIR/backend.tf"
terraform {
  backend "${BACKEND}" {
    bucket  = "${BUCKET}"
    key     = "${PROJECT}/${ENVIRONMENT}/${STATEFILE}"
    region  = "${REGION}"
  }
}
EOF
cat "$DIR/backend.tf"

#VSPHERE_CREDENTIALS="${DIR}/${CREDENTIALS}"
#export VSPHERE_CREDENTIALS
#export DATAFILE
/bin/rm -rf "$PWD/common_configuration.tfvars" 2>/dev/null
/bin/rm -rf "$DIR/.terraform" 2>/dev/null
echo "setenv: Initializing terraform"
terraform init 


