# E2B Docker Template Builder

This repo has dockerfiles for building E2B templates. The purpose is to have some templates ready for
development use on E2B, especially for use with an LLM.

*Note* These will all run as regular Docker containers as well.

## Templates
Most templates include webshell with a preconfigured user, `sandboxuser`. Copy the `.env.example` to `.env` and set the password for the user.

## LibreChat
https://github.com/jmaddington/LibreChat.git

## Wordpress
A fully functional Wordpress installation, includes:
-Apache
-MariaDB
-Wordpress
-Webshell

Copy `.env.example` to `.env` and set the values for the database, and the Wordpress admin user. The `.env` file is copied
to the container and deleted after initial setup.

After startup, `wp-cli` will run to configure the Wordpress site and add the admin user with creds from the `.env` file.
After a few seconds you should have a fully functional Wordpress site.

Build locally:
`docker build -t <tag> ./wordpress`

Run locally:
`docker run -d -p 80:80 -p 4200:4200 <tag>>`

## Webshell
An Ubuntu image with Webshell preinstalled. The user is `sandboxuser` with the password set in the `.env` file.

## Building Templates
To build a template, you need to have the E2B CLI installed and authenticated. You can install the CLI with `npm i -g @e2b/cli` and authenticate with `e2b auth login`.

The command to build a template is:

`e2b template build ---path <folder> --name <template-name>  --cpu-count <cpu-count> --memory-mb <memory-mb> --cmd <start-command>`

Examples:
`e2b template build --path ./librechat --name librechat  --cpu-count 2  --memory-mb 2048 --cmd "/usr/local/bin/start-librechat.sh"`

`e2b template build --path ./wordpress --name wordpress  --cpu-count 2  --memory-mb 2048 --cmd "/usr/local/bin/start-services.sh"`

`e2b template build --path ./webshell --name webshell  --cpu-count 2  --memory-mb 2048 --cmd "/usr/local/bin/start-shellinabox.sh"`

`e2b template build --path ./ubuntu22.04 --name ubuntu2204  --cpu-count 2  --memory-mb 4096 --cmd "/usr/local/bin/start-shellinabox.sh"`

`e2b template build --path ./ubuntu24.04 --name ubuntu2404  --cpu-count 2  --memory-mb 4096 --cmd "/usr/local/bin/start-shellinabox.sh"`


**YOU MUST SET THE CMD** for the template to start correctly. It doesn't matter that it is in the dockerfile, the CLI needs it set.