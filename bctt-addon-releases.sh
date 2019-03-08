#!/usr/bin/env bash

# GITHUB ADD-ON RELEASER
#
# READ BEFORE USING:
#
# YOU CAN PASS THE FOLLOWING ARGS:
# - r = enter the name of the github repo as it appears.
# - v =  enter the version number that you would like to be released.
#
# NOTES:
# 
#
# Disclaimer:
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

# ----- START EDITING HERE -----

# THE GITHUB ACCESS TOKEN, GENERATE ONE AT: https://github.com/settings/tokens
GITHUB_ACCESS_TOKEN=""

# GITHUB user who owns the repo
GITHUB_REPO_OWNER="benunc"

# ----- STOP EDITING HERE -----

# ASSEMBLE ARGS PASSED TO SCRIPT.
while getopts r:v: option
do
 case "${option}"
 in
 r) GITHUB_REPO_NAME=${OPTARG};;
 v) VERSION=${OPTARG};;

 esac
done

set -e
clear

echo "-------------------------------------------------------------"
echo "    Welcome to the Better Click To Tweet Add-on Releaser     "
echo "-------------------------------------------------------------"

# Is GITHUB_REPO_NAME var set?
if [ "$GITHUB_REPO_NAME" = "" ]; then
    read -p "GitHub Add-on repo name: " GITHUB_REPO_NAME
fi

# Is VERSION var set?
if [ "$VERSION" = "" ]; then
    read -p "Tag and release version for $GITHUB_REPO_NAME: " VERSION
fi

# Lowercase a slug guess from repo to speed things up.
SLUG_GUESS="$(tr [A-Z] [a-z] <<< "$GITHUB_REPO_NAME")"

read -p "Plugin slug [$SLUG_GUESS]:" PLUGIN_SLUG
PLUGIN_SLUG=${PLUGIN_SLUG:-$SLUG_GUESS}

# Verify there's a version number
# now check if $x is "y"
if [ "$VERSION" = "" ]; then
    # do something here!
    read -p "You forgot the plugin version: " VERSION
fi

echo "----------------------------------------------------"
echo "    GETTING READY TO RELEASE " GITHUB_REPO_NAME
echo "----------------------------------------------------"

clear

# ASK INFO
echo ""
echo "Before continuing, confirm that you have done the following :)"
echo ""
read -p " - Added a changelog for "${VERSION}"?"
read -p " - Set version in the readme.txt and main file to "${VERSION}"?"
read -p " - Set stable tag in the readme.txt file to "${VERSION}"?"
read -p " - Updated the POT file?"
read -p " - Updated the version number in the LICENSE callback?"
read -p " - Committed all changes up to GitHub?"
echo ""
read -p "Press [ENTER] to begin releasing "${VERSION}
clear


# SET VARS
ROOT_PATH=$(pwd)"/"
TEMP_GITHUB_REPO=${PLUGIN_SLUG}"-git"
GIT_REPO="git@github.com:"${GITHUB_REPO_OWNER}"/"${GITHUB_REPO_NAME}".git"

# DELETE OLD TEMP DIRS BEFORE BEGINNING
rm -Rf "$ROOT_PATH$TEMP_GITHUB_REPO"
rm -Rf "$PLUGIN_SLUG"

# CLONE GIT DIR
echo "Cloning GIT repository from GitHub"
git clone --progress $GIT_REPO $TEMP_GITHUB_REPO || { echo "Unable to clone repo."; exit 1; }

# MOVE INTO GIT DIR
cd "$ROOT_PATH$TEMP_GITHUB_REPO"

# LIST BRANCHES
clear
git fetch origin
echo "Which branch do you wish to deploy?"
git branch -r || { echo "Unable to list branches."; exit 1; }
echo ""
read -p "origin/master" BRANCH

# If no branch default var to master
if [ "$BRANCH" = "" ]; then
    BRANCH="master"
fi

# Switch Branch if not master
if [ "$BRANCH" != "master" ]; then
  echo "Switching to branch"
fi

git checkout ${BRANCH} || { echo "Unable to checkout branch."; exit 1; }
echo ""
read -p "Press [ENTER] to deploy \""${BRANCH}"\" branch"

# RUN COMPOSER
if [ -f composer.json ]; then
    composer install
fi

if [ -f package.json ]; then
    npm install
    npm run build
fi

# Checking for git submodules
if [ -f .gitmodules ];
then
echo "Submodule found. Updating"
git submodule init
git submodule update
else
echo "No submodule exists"
fi

# PROMPT USER
echo ""
read -p "Press [ENTER] to commit release "${VERSION}" to GitHub"
echo ""

# CREATE THE GITHUB RELEASE
echo "Creating GitHub tag and release"
git tag -a "v"${VERSION} -m "Tagging version: $VERSION." -m "The ZIP and TAR.GZ here are not production-ready." -m "Build by checking out the release and running composer install, npm install, and npm run build."

git push origin --tags # push tags to remote
echo "";


# REMOVE UNWANTED FILES & FOLDERS
echo "Removing unwanted files..."
rm -Rf assets/src
rm -Rf tests
rm -Rf bower
rm -Rf tmp
rm -Rf node_modules
rm -Rf apigen
rm -Rf .idea
rm -Rf .github
rm -Rf vendor

# Hidden Files
rm -rf .bowerrc
rm -rf .babelrc
rm -rf .scrutinizer.yml
rm -rf .travis.yml
rm -rf .CONTRIBUTING.md
rm -rf .gitattributes
rm -rf .gitignore
rm -rf .gitmodules
rm -rf .editorconfig
rm -rf .travis.yml
rm -rf .jscrsrc
rm -rf .jshintrc
rm -rf .eslintrc
rm -rf .eslintignore
rm -rf .nvmrc

# Other Files
rm -rf bower.json
rm -rf composer.json
rm -rf composer.lock
rm -rf package.json
rm -rf package-lock.json
rm -rf Gruntfile.js
rm -rf GulpFile.js
rm -rf gulpfile.js
rm -rf grunt-instructions.md
rm -rf composer.json
rm -rf phpunit.xml
rm -rf phpunit.xml.dist
rm -rf phpcs.ruleset.xml
rm -rf phpcs.xml
rm -rf LICENSE
rm -rf LICENSE.txt
rm -rf README.md
rm -rf CHANGELOG.md
rm -rf CODE_OF_CONDUCT.md
rm -rf readme.md
rm -rf postcss.config.js
rm -rf webpack.config.js
rm -rf docker-compose.yml

wait
echo "All cleaned! Proceeding..."


# USE GREN TO PRETTY UP THE RELEASE NOTES (OPTIONAL)
# gren release --token ${GITHUB_ACCESS_TOKEN}
# echo "GitHub Release Created...";

# REMOVE .GIT DIR AS WE'RE DONE WITH GIT
cd "$ROOT_PATH$TEMP_GITHUB_REPO"
rm -Rf .git
sleep 3
clear
read -p "Check to make sure .git is removed"
echo ""

# Create the Zip File
echo "Creating zip package..."
cd "$ROOT_PATH"
mv "$TEMP_GITHUB_REPO" "$PLUGIN_SLUG" #Rename cleaned repo

read -p "check renamed repo"
echo ""
wait
zip -r "$PLUGIN_SLUG".zip "$PLUGIN_SLUG" #Zip it
wait

mv "$PLUGIN_SLUG" "$TEMP_GITHUB_REPO" #Rename back to temp dir
wait
echo "Zip package created"
echo ""

# REMOVE EVERYTHING BUT THE README FILE IN THE FOLDER
echo "Creating readme.txt file for website:"
mv "$ROOT_PATH$TEMP_GITHUB_REPO"/readme.txt /tmp/
rm -rf "$ROOT_PATH$TEMP_GITHUB_REPO"
mkdir "$ROOT_PATH$PLUGIN_SLUG"
mv /tmp/readme.txt "$ROOT_PATH$PLUGIN_SLUG"
echo ""

# SECURE COPY FILES OVER TO GIVEWP.COM
echo "------------------------------------------------------------"
read -p "Are you ready to move the files to betterclicktotweet.com?"
echo "------------------------------------------------------------"
scp "$PLUGIN_SLUG".zip bctt-user@192.34.56.118:/srv/users/bctt-user/apps/betterclicktotweet/public/wp-content/uploads/edd/addons/
scp "$ROOT_PATH$PLUGIN_SLUG"/readme.txt bctt-user@192.34.56.118:/srv/users/bctt-user/apps/betterclicktotweet/public/wp-content/uploads/edd/addons/"$PLUGIN_SLUG".txt
echo "Files transferred..."
echo ""

# REMOVE THE TEMP DIRS
echo "Cleaning up the directory..."
rm -Rf "$ROOT_PATH$TEMP_GITHUB_REPO"
rm -Rf "$PLUGIN_SLUG"

# DONE, BYE
echo "Releaser done :D"
echo "What's left? Update the version number in EDD!"