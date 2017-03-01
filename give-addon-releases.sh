#!/usr/bin/env bash

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

set -e
clear

echo "--------------------------------------------"
echo "    Welcome to the Give Add-on Release      "
echo "--------------------------------------------"

read -p "GitHub Add-on repo name: " GITHUB_REPO_NAME
read -p "Plugin slug: " PLUGIN_SLUG
read -p "Tag and release version: " VERSION

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
read -p "origin/" BRANCH

# Switch Branch
echo "Switching to branch"
git checkout ${BRANCH} || { echo "Unable to checkout branch."; exit 1; }
echo ""
read -p "Press [ENTER] to deploy \""${BRANCH}"\" branch"

# REMOVE UNWANTED FILES & FOLDERS
echo "Removing unwanted files..."
rm -Rf .git
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
rm -f readme.md
wait
echo "All cleaned! Proceeding..."


# PROMPT USER
echo ""
read -p "Press [ENTER] to commit release "${VERSION}" to GitHub"
echo ""

# CREATE THE GITHUB RELEASE
echo "Creating GITHUB release"
API_JSON=$(printf '{ "tag_name": "%s","target_commitish": "%s","name": "%s", "body": "Release of version %s", "draft": false, "prerelease": false }' $VERSION $BRANCH $VERSION $VERSION)
RESULT=$(curl --data "${API_JSON}" https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/releases?access_token=${GITHUB_ACCESS_TOKEN})
wait
echo RESULT
echo "GitHub Release Created...";
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

# FTP to GiveWP.com


# REMOVE THE TEMP DIRS
echo "Cleaning up the directory:"
rm -Rf "$ROOT_PATH$TEMP_GITHUB_REPO"

# DONE, BYE
echo "Releaser done :D"