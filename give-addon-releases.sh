#!/usr/bin/env bash

# ARGS:
# - R = enter the name of the github repo as it appears.
# - v =  enter the version number that you would like to be released.
#
# NOTES:
#
# You need the following installed globally:
#
# 1. github-release-notes : https://github.com/github-tools/github-release-notes
# 2. github-changelog-generator : https://github.com/skywinder/github-changelog-generator
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
GITHUB_REPO_OWNER="WordImpress"

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

echo "--------------------------------------------"
echo "    Welcome to the Give Add-on Releaser     "
echo "--------------------------------------------"

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

# Switch Branch
echo "Switching to branch"
git checkout ${BRANCH} || { echo "Unable to checkout branch."; exit 1; }
echo ""
read -p "Press [ENTER] to deploy \""${BRANCH}"\" branch"

## Checking for git submodules
if [ -f .gitmodules ];
then
echo "Submodule found. Updating"
git submodule init
git submodule update
else
echo "No submodule exists"
fi

# UPDATE CHANGELOG.MD FILE
echo "Updating CHANGELOG.md release"
github_changelog_generator ${GITHUB_REPO_OWNER}"/"${GITHUB_REPO_NAME} --token ${GITHUB_ACCESS_TOKEN}
wait
clear

# REMOVE UNWANTED FILES & FOLDERS
echo "Removing unwanted files..."
rm -Rf tests
rm -Rf bower
rm -Rf tmp
rm -Rf node_modules
rm -Rf apigen
rm -Rf .idea
rm -Rf .github
rm -f .bowerrc
rm -f .scrutinizer.yml
rm -f .travis.yml
rm -f bower.json
rm -f composer.json
rm -f composer.lock
rm -f package.json
rm -f package-lcok.json
rm -f .CONTRIBUTING.md
rm -f .gitattributes
rm -f .gitignore
rm -f .gitmodules
rm -f .editorconfig
rm -f .travis.yml
rm -f Gruntfile.js
rm -f GulpFile.js
rm -f gulpfile.js
rm -f grunt-instructions.md
rm -f .jscrsrc
rm -f .jshintrc
rm -f composer.json
rm -f phpunit.xml
rm -f phpunit.xml.dist
rm -f LICENSE
rm -f LICENSE.txt
rm -f README.md
rm -f CHANGELOG.md
rm -f readme.md
wait
echo "All cleaned! Proceeding..."


# PROMPT USER
echo ""
read -p "Press [ENTER] to commit release "${VERSION}" to GitHub"
echo ""

# CREATE THE GITHUB RELEASE
echo "Creating GitHub tag and release"
git tag -a ${VERSION} -m "Tagging version: $VERSION"
git push origin --tags # push tags to remote

# USE GREN TO PRETTY UP THE RELEASE NOTES
gren release --token ${GITHUB_ACCESS_TOKEN}
echo "GitHub Release Created...";

# REMOVE .GIT DIR
rm -Rf .git
sleep 3
clear

# Create the Zip File
echo "Creating zip package..."
cd "$ROOT_PATH"
mv "$TEMP_GITHUB_REPO" "$PLUGIN_SLUG" #Rename cleaned repo
wait
zip -r "$PLUGIN_SLUG".zip "$PLUGIN_SLUG" #Zip it
wait
mv "$PLUGIN_SLUG" "$TEMP_GITHUB_REPO" #Rename back to temp dir
wait
echo "Zip package created"
echo ""

# REMOVE EVERYTHING BUT THE README FILE IN THE FOLDER
echo "Creatings readme.txt file for website:"
mv "$ROOT_PATH$TEMP_GITHUB_REPO"/readme.txt /tmp/
rm -rf "$ROOT_PATH$TEMP_GITHUB_REPO"
mkdir "$ROOT_PATH$PLUGIN_SLUG"
mv /tmp/readme.txt "$ROOT_PATH$PLUGIN_SLUG"
echo ""

# SECURE COPY FILES OVER TO GIVEWP.COM
#scp "$PLUGIN_SLUG".zip client_devin@54.156.11.193:/data/s828204/dom24402/dom24402/downloads/plugins LIVE
echo "--------------------------------------------------"
read -p "Are you ready to move the files to givewp.com?"
echo "--------------------------------------------------"
scp "$PLUGIN_SLUG".zip # ENTER CONNECT INFO
scp "$ROOT_PATH$PLUGIN_SLUG" # ENTER CONNECT INFO
echo "Files transferred..."
echo ""

# REMOVE THE TEMP DIRS
echo "Cleaning up the directory..."
rm -Rf "$ROOT_PATH$TEMP_GITHUB_REPO"

# DONE, BYE
echo "Releaser done :D"