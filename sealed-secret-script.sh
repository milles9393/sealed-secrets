#!/bin/bash
# olindhol@redhat.com & mgloerfe@redhat.com
# Simple script for using sealed-secrets on OCP

HELP() {


  echo "This script takes care of the creation of the sealed-secret.yaml file."
  echo 
  echo "To use, run: 'sh sealed-secret.sh [-s, -n,-f, -e]"
  echo 
  echo "options:"
  echo "-s      Choose the name of the secret. The name will be coverted to lowercase."
  echo "-n      Choose your namespace."
  echo "-f      Choose the file that kubeseal should use in order to generate the sealed-secret.yaml file."

  exit 1
}

which oc > /dev/null

if [ $? == 1 ]
then
  echo "oc client not found. Please install."
  exit 1
fi

which kubeseal > /dev/null

if [ $? == 1 ]
then
  echo "kubeseal not found. Please install."
  exit 1
fi

while getopts ":s:n:f:h" opt; do
  case ${opt} in
    s )
      secret_name=${OPTARG}
      ;;
    n )
      namespace=${OPTARG}
      ;;
    f )
      from_file=${OPTARG} 
      ;;
    h )
      HELP
      exit 0
      ;;
    \? )
      echo "Invalid option: '$OPTARG' run -h for more information." 1>&2
      exit 1
      ;;
    : )
      echo "Invalid option: '$OPTARG' requires an argument. Run -h for more information." 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

secret_name_lowercase=$( echo ${secret_name} | tr '[:upper:]' '[:lower:]' )

oc create secret generic ${secret_name_lowercase} --dry-run=client --from-file=${from_file} -n ${namespace} -o yaml> secret-prop.yml
kubeseal --controller-name=sealed-secrets-controller --controller-namespace=sealed-secrets -o yaml < secret-prop.yml > sealed-secret-"${secret_name_lowercase}".yml
echo "sealed-secret-"${secret_name_lowercase}".yml has now been created. You can add it to git."
echo "Secret: ${secret_name_lowercase} has been created."

#echo -e "{{- if .Values.deployEnv.${environment} }}\n$(cat sealed-secret.yml)" > sealed-secret-${environment}.yml
