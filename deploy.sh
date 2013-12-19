#! /usr/bin/env bash


WRAPPER_DIR=$(dirname $(readlink -e $BASH_SOURCE))
SCRIPT_PATH="$WRAPPER_DIR/vendor/dg/ftp-deployment/Deployment/deployment.php"
RECEPIENTS=()
RECEPIENTS_FILE="deployment.recepients"


#Load email addresses of people for whom the script should be encrypted
#The gpg public keys have to be present in the system
#The list is a file with one email per line and NEW LINE AT THE END
while read LINE
do
	if [ ! -z "$LINE" ]
	then
		RECEPIENTS+=("$LINE")
	fi
done < $RECEPIENTS_FILE


#check if the user input is valid
if [ "$#" -lt 2 ]
then
	echo "Usage: deploy.sh <environment_name> <upload|encrypt|decrypt> [--test]"
	exit 1
fi

INI_FILENAME="deployment.$1.ini"
if [ ! -f "$INI_FILENAME" ] && [ ! -f "$INI_FILENAME.gpg" ]
then
	echo "There is no file $INI_FILENAME or $INI_FILENAME.gpg. Nothing to do."
	exit 1
fi

if [ "$2" != "upload" ] && [ "$2" != "decrypt" ] && [ "$2" != "encrypt" ]
then
	echo "Valid commands are upload, decrypt and encrypt"
	exit 1
fi

if [ "$3" != "--test" ] && [ "$#" -gt 2 ]
then
	echo "The only valid option is --test"
	exit 1
fi


#peroform action
if [[ "$2" = "upload" ]]
then
	if [ ! -f "$INI_FILENAME.gpg" ]
	then
		echo "Nothing to decrypt. There must be a $INI_FILENAME.gpg in this folder"
		exit 1
	fi
	gpg -d $INI_FILENAME.gpg > $INI_FILENAME
	php $SCRIPT_PATH $INI_FILENAME $3
	rm $INI_FILENAME


elif [[ "$2" = "decrypt" ]]
then
	if [ ! -f "$INI_FILENAME.gpg" ]
	then
		echo "Nothing to decrypt. There must be a $INI_FILENAME.gpg in this folder"
		exit 1
	fi

	if [ -f $INI_FILENAME ]
	then
		rm $INI_FILENAME
	fi

	gpg -d $INI_FILENAME.gpg > $INI_FILENAME
	if [ -s $INI_FILENAME ]
	then
		rm $INI_FILENAME.gpg
	else
		rm $INI_FILENAME
		echo "The deployment ini file could not be decrypted"
	fi

elif [[ "$2" = "encrypt" ]]
then
	if [ ! -f "$INI_FILENAME" ]
	then
		echo "Nothing to encrypt. There must be a $INI_FILENAME in this folder"
		exit 1
	fi

	if [ -f $INI_FILENAME.gpg ]
	then
		rm $INI_FILENAME.gpg
	fi

	recepstring=""
	for recepient in "${RECEPIENTS[@]}"
		do
			recepstring+=" -r "
			recepstring+=$recepient
		done
	gpg -e $recepstring $INI_FILENAME
	rm $INI_FILENAME
	echo "SUCCESS! The file was encrypted for: ${RECEPIENTS[@]}"
fi

