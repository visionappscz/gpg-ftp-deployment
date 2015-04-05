gpg-ftp-deployment
==================

A wrapper script for ftp-deployment tool.

The aim of this script is to provide ondemand encryption and decryption of credentials for use by the ftp-deployment tool. Once encrypted the files can then by shared over git and such.

The encryption is handled by gpg and all who are expected to use the encrypted file must have made their certificate available at encryption time. The certificates to use during encryption are specified by email addresses in file named deployment.recipients at the same location as the deployment configuration files.

This script assumes that the deployment configuration files are named in the following manner: "deployment.<name_of_environment>.ini[.gpg]".

The name of the environment is passed in as a first argument, the desired action as a second argument.

The upload action can be run in test mode with the -t option. No files will be changed, but it will be shown what would have had happend.


DEPENDENCIES:

php (with ssh2), gpg, composer


INSTALLATION:

1/ Clone this repository

    git clone git@github.com:mbohal/gpg-ftp-deployment.git

2/ Navigate to the root of the project (where deploy.js is)

    cd /path/to/project

3/ Install dependencies

    composer install

On some systems, namely Mac OSX, the correct path to the istalation script can not be resolved automatically. To fix it:
```
$ cd /absolute/path/to/dir/containing/the/deploy.sh/script
$ sed -i "s|^WRAPPER_DIR.*$|WRAPPER_DIR=$(pwd)|" deploy.sh
```


USAGE:

    deploy.sh [options] <environment_name> <upload|encrypt|decrypt>
    -t              Run in test mode
    -r FILENAME     Recipients for whom to encrypt the ini files are listed in FILENAME


EXAMPLES:

Sync with server (requires file: deployment.preview.ini.gpg):

    deploy.sh preview upload


Decrypt file with production environment credentials (requires file: deployment.production.ini.gpg):

    deploy.sh production decrypt


Encrypt file with testing environment credentials (requires files: deployment.testing.ini and deployment.recepients):

    deploy.sh testing encrypt
