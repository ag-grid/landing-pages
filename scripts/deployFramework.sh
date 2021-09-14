#!/bin/bash

if [ "$#" -lt 1 ]
  then
    echo "You must supply framework to deploy"
    echo "For example: ./scripts/deployFramework.sh react"
    exit 1
fi

FRAMEWORK=$1

if [ ! -d "$FRAMEWORK-grid" ];
then
  echo "$FRAMEWORK-grid does NOT exist! Please confirm framework specified."
  exit 1;
fi

function checkFileExists {
    file=$1
    if ! [[ -f "$file" ]]
    then
        echo "File [$file] doesn't exist - exiting script.";
        exit;
    fi
}

# zip contents to be copied over and deployed
DATE=`date +%Y%m%d`
FILENAME=deployment_"$FRAMEWORK"_$DATE.zip
zip -FSr $FILENAME "$FRAMEWORK-grid"

# $2 is optional skipWarning argument
if [ "$2" != "skipWarning" ]; then
    while true; do
      echo    ""
      echo    "*********************************** ******* ************************************************"
      echo    "*********************************** WARNING ************************************************"
      echo    "*********************************** ******* ************************************************"
      read -p "This script update the landing page for the framework specified!. Do you wish to continue [y/n]? " yn
      case $yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) echo "Please answer [y]es or [n]o.";;
      esac
    done
fi

CREDENTIALS_LOCATION=$HOME/$CREDENTIALS_FILE
SSH_LOCATION=$HOME/$SSH_FILE

# a few safety checks
if [ -z "$CREDENTIALS_LOCATION" ]
then
      echo "\$CREDENTIALS_LOCATION is not set"
      exit;
fi

if [ -z "$SSH_LOCATION" ]
then
      echo "\$SSH_LOCATION is not set"
      exit;
fi

checkFileExists $CREDENTIALS_LOCATION
checkFileExists $SSH_LOCATION

# upload file - note that this will be uploaded to the archive dir as this is where this ftps home account is
# we'll move this file up one in the next step
curl --netrc-file $CREDENTIALS_LOCATION --ftp-create-dirs -T $FILENAME ftp://ag-grid.com/

# move file from the archives dir to the framework landing page
ssh -i $SSH_LOCATION ceolter@ag-grid.com "mv public_html/archive/$FILENAME ./$FRAMEWORK-grid.ag-grid.com"

# unzip new contents
unzip "$FRAMEWORK-grid.ag-grid.com/$FILENAME" -d $FRAMEWORK-grid.ag-grid.com/


