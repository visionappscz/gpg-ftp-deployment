gpg-ftp-deployment
==================

A wrapper script for ftp-deployment tool.

The aim of this script is to provide ondemand encryption and decryption of credentials for use by the ftp-deployment tool. Once encrypted the files can then by shared over git or such.

The encryption is handled by gpg and all who are expected to use the encrypted file must have their certificate added at encryption time. The recepients of the encrypted files are listed in file named deployment.recepients at the same location as the deployment configuration files.

this script assumes taht the deployment configuration files are named in the following manner: "deployment.<name_of_environment>.ini[.gpg]". The name of the environment is opassed in as a first argument, the desired action as a second argument.


USAGE:

	deploy.sh <environment_name> <upload|encrypt|decrypt>


EXAMPLES:

	Sync with server (requires file: deployment.preview.ini.gpg):
		deploy.sh preview upload


	Decrypt file with production environment credentials (requires file: deployment.production.ini.gpg):
		deploy.sh production decrypt


	Encrypt file with testing environment credentials (requires files: deployment.testing.ini and deployment.recepients):
		deploy.sh testing encrypt
