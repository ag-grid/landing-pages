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
cd "$FRAMEWORK-grid"
zip -FSr ../$FILENAME *
cd ..

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
echo "Copying zipped deployment to ag-grid"
curl --netrc-file $CREDENTIALS_LOCATION --ftp-create-dirs -T $FILENAME ftp://ag-grid.com/ && echo "Zipped file copied to ag-grid"

# move file from the archives dir to the framework landing page
echo "Moving deployment file from archives to root directory"
ssh -i $SSH_LOCATION ceolter@ag-grid.com "mv public_html/archive/$FILENAME ./"

# clear out old contents
echo "Clearing out contents of $FRAMEWORK-grid.ag-grid.com"
#ssh -i $SSH_LOCATION ceolter@ag-grid.com "rm -rf /home/ceolter/$FRAMEWORK-grid.ag-grid.com/*"

# unzip new contents
echo "Unzipping contents of deployment file to $FRAMEWORK-grid.ag-grid.com"
if [ -d /home/ceolter/$FILENAME ]
then
    echo "File exists!!!!"
else
  echo "File doesn't exists????"
fi

echo "unzip /home/ceolter/$FILENAME -d /home/ceolter/$FRAMEWORK-grid.ag-grid.com/"
#unzip /home/ceolter/$FILENAME -d /home/ceolter/$FRAMEWORK-grid.ag-grid.com/

