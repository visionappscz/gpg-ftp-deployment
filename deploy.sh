#!/usr/bin/env bash


WRAPPER_DIR=$(dirname $(readlink -e $BASH_SOURCE))
SCRIPT_PATH="$WRAPPER_DIR/vendor/dg/ftp-deployment/Deployment/deployment.php"
RECIPIENTS=()
RECIPIENTS_FILE="deployment.recipients"
TEST_OPTION_STRING=""
COMMANDS=("upload" "encrypt" "decrypt")
HELP_TEXT="Usage: deploy.sh [options] <environment_name> <upload|encrypt|decrypt> \n\n
    -t              Run in test mode. nofiles will be changed. \n\n
    -r FILENAME     Specifies custom recipients file. Recipients for whom to encrypt the ini file are listed in FILENAME.\n"

# parse options
while getopts :r:th opt
do
    case $opt in
        r)
            RECIPIENTS_FILE=$OPTARG
            ;;
        t)
            TEST_OPTION_STRING="--test"
            ;;
        h)
            echo -e $HELP_TEXT
            exit
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit 1
            ;;
  esac
done

# check if the required positional arguments are present
if [ $(( $# - $OPTIND )) -lt 1 ]
then
    echo -e $HELP_TEXT
    exit 1
fi

# set the positional arguments
ENVIRONMENT=${@:$OPTIND:1}
ACTION=${@:$OPTIND+1:1}

# check weather the deployment ini file exists
INI_FILENAME="deployment.$ENVIRONMENT.ini"
if [ ! -f "$INI_FILENAME" ] && [ ! -f "$INI_FILENAME.gpg" ]
then
    echo "There is no file $INI_FILENAME or $INI_FILENAME.gpg. Nothing to do."
    exit 1
fi

# check weather the action is valid
if [ "$ACTION" != "upload" ] && [ "$ACTION" != "decrypt" ] && [ "$ACTION" != "encrypt" ]
then
    echo "Valid commands are upload, decrypt and encrypt"
    exit 1
fi


#peroform action
if [[ "$ACTION" = "upload" ]]
then
    if [ ! -f "$INI_FILENAME.gpg" ]
    then
        echo "Nothing to decrypt. There must be a $INI_FILENAME.gpg in this folder"
        exit 1
    fi
    $(gpg -d $INI_FILENAME.gpg > $INI_FILENAME)

    # delete unencrypted ini file on interrupt
    trap '{ rm $INI_FILENAME; exit 1; }' INT

    php $SCRIPT_PATH $INI_FILENAME $TEST_OPTION_STRING
    rm $INI_FILENAME
    exit


elif [[ "$ACTION" = "decrypt" ]]
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

    $(gpg -d $INI_FILENAME.gpg > $INI_FILENAME)
    RET_CODE=$?
    if [ "$RET_CODE" = 0 ]
    then
        rm $INI_FILENAME.gpg
        echo "File $INI_FILENAME was decrypted"
        exit
    else
        rm $INI_FILENAME
        echo "The file $INI_FILENAME could not be decrypted."
        exit 1
    fi

elif [[ "$ACTION" = "encrypt" ]]
then
    #check if ini file exists
    if [ ! -f "$INI_FILENAME" ]
    then
        echo "Nothing to encrypt. There must be a $INI_FILENAME in this folder"
        exit 1
    fi

    #check if recipients file exists
    if [ ! -f "$RECIPIENTS_FILE" ]
    then
        echo "The file $RECIPIENTS_FILE does not exist. You can specify custom recipients file with the -r option."
        exit 1
    fi


    if [ -f $INI_FILENAME.gpg ]
    then
        rm $INI_FILENAME.gpg
    fi


    while read LINE
    do
        if [ ! -z "$LINE" ]
        then
            RECIPIENTS+=("$LINE")
        fi
    done < $RECIPIENTS_FILE

    RECIPIENT_STRING=""
    for RECIPIENT in "${RECIPIENTS[@]}"
    do
        RECIPIENT_STRING+=" -r "
        RECIPIENT_STRING+=$RECIPIENT
    done

    $(gpg -e $RECIPIENT_STRING $INI_FILENAME)
    RET_CODE=$?
    if [ "$RET_CODE" = 0 ]
    then
        rm $INI_FILENAME
        echo "SUCCESS! The file $INI_FILENAME was encrypted for: ${RECIPIENTS[@]}"
        exit
    else
        echo "Could not encrypt file $INI_FILENAME."
        exit 1
    fi
fi

