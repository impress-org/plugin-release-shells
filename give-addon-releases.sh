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
# You need the following installed globally:
#
# 1. github-release-notes : https://github.com/github-tools/github-release-notes
# 2. github-changelog-generator : https://github.com/skywinder/github-changelog-generator
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
GITHUB_REPO_OWNER=""

# ----- STOP EDITING HERE -----

# ASSEMBLE ARGS PASSED TO SCRIPT.
while getopts r:v: option
do
 case "${option}"
 in
 r) GITHUB_REPO_NAME=${OPTARG};;
 v) VERSION=${OPTARG};;
 *) echo "Incorrect arguments passed in. Missing [-r] or [-v]" >&2
	 exit 1;;
 esac
done

set -e
clear

echo "--------------------------------------------"
echo "    Welcome to the Give Add-on Releaser     "
echo "--------------------------------------------"

# Is GITHUB_REPO_NAME var set?
if [ "$GITHUB_REPO_NAME" = "" ]; then
    read -rp "GitHub Add-on repo name: " GITHUB_REPO_NAME
fi

# Is VERSION var set?
if [ "$VERSION" = "" ]; then
    read -rp "Tag and release version for $GITHUB_REPO_NAME: " VERSION
fi

# Lowercase a slug guess from repo to speed things up.
SLUG_GUESS="$(tr 'A-Z' 'a-z' <<< "$GITHUB_REPO_NAME")"

read -rp "Plugin slug [$SLUG_GUESS]:" PLUGIN_SLUG
PLUGIN_SLUG=${PLUGIN_SLUG:-$SLUG_GUESS}

# Verify there's a version number
# now check if $x is "y"
if [ "$VERSION" = "" ]; then
    # do something here!
    read -rp "You forgot the plugin version: " VERSION
fi

echo "----------------------------------------------------"
echo "    GETTING READY TO RELEASE " GITHUB_REPO_NAME
echo "----------------------------------------------------"

clear

# ASK INFO
echo ""
echo "Before continuing, confirm that you have done the following :)"
echo ""
read -rp " - Added a changelog for ${VERSION}?"
read -rp " - Set version in the readme.txt and main file to ${VERSION}?"
read -rp " - Set stable tag in the readme.txt file to ${VERSION}?"
read -rp " - Updated the POT file?"
read -rp " - Committed all changes up to GitHub?"
echo ""
read -rp "Press [ENTER] to begin releasing ${VERSION}"
clear


# SET VARS
ROOT_PATH=$(pwd)"/"
TEMP_GITHUB_REPO=${PLUGIN_SLUG}"-git"
GIT_REPO="git@github.com:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git"

# DELETE OLD TEMP DIRS BEFORE BEGINNING
rm -Rf "$ROOT_PATH$TEMP_GITHUB_REPO"

# CLONE GIT DIR
echo "Cloning GIT repository from GitHub"
git clone --progress "$GIT_REPO" "$TEMP_GITHUB_REPO" || { echo "Unable to clone repo."; exit 1; }

# MOVE INTO GIT DIR
cd "$ROOT_PATH$TEMP_GITHUB_REPO"

# LIST BRANCHES
clear
git fetch origin
echo "Which branch do you wish to deploy?"
git branch -r || { echo "Unable to list branches."; exit 1; }
echo ""
read -rp "origin/master" BRANCH

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
read -rp "Press [ENTER] to deploy \"${BRANCH}\" branch"

# RUN COMPOSER
if [ -f composer.json ]; then
    composer install --no-dev
fi

echo "Running npm install and production if available."
if [ -f package.json ]; then
npm install --if-present
npm run production --if-present
fi

# Checking for git submodules
if [ -f .gitmodules ]; then
echo "Submodule found. Updating"
git submodule init
git submodule update
else
echo "No submodule exists"
fi

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

# Hidden Files
rm -f .bowerrc
rm -f .babelrc
rm -f .scrutinizer.yml
rm -f .travis.yml
rm -f .CONTRIBUTING.md
rm -f .gitattributes
rm -f .gitignore
rm -f .gitmodules
rm -f .editorconfig
rm -f .travis.yml
rm -f .jscrsrc
rm -f .jshintrc
rm -f .eslintrc
rm -f .eslintignore
rm -f .eslintrc.json
rm -f .prettierignore
rm -f .stylelintrc.json
rm -f .huskyrc.json
rm -f .lintstagedrc.json

# Other Files
rm -f bower.json
rm -f composer.json
rm -f composer.lock
rm -f package.json
rm -f package-lock.json
rm -f Gruntfile.js
rm -f GulpFile.js
rm -f gulpfile.js
rm -f grunt-instructions.md
rm -f composer.json
rm -f phpunit.xml
rm -f phpunit.xml.dist
rm -f phpcs.ruleset.xml
rm -f LICENSE
rm -f LICENSE.txt
rm -f README.md
rm -f CHANGELOG.md
rm -f CODE_OF_CONDUCT.md
rm -f readme.md
rm -f postcss.config.js
rm -f webpack.config.js

wait
echo "All cleaned! Proceeding..."

# PROMPT USER
echo ""
read -rp "Press [ENTER] to commit release ${VERSION} to GitHub"

echo ""

# CREATE THE GITHUB RELEASE
echo "Creating GitHub tag and release"
git tag -a "${VERSION}" -m "Tagging version: $VERSION"
git push origin --tags # push tags to remote
echo "";

# UPDATE Give-Add-on-Releases README.md
NEWLINE="
"
HTMLVER="\`${VERSION}\`"
TODAYPRETTY=$(date -u +"%m-%d-%Y @ %H:%M")
echo "";
echo "--------------------------------------------------"
echo "Updating give-addon-releases...";
echo "--------------------------------------------------"
git clone --progress "git@github.com:impress-org/give-addon-releases.git" "give-addon-releases" || { echo "Unable to clone repo."; exit 1; }
cd "give-addon-releases"
sed -i -e "s/|:----------|:-------------:|------:|/|:----------|:-------------:|------:|\\${NEWLINE}| ${GITHUB_REPO_NAME} | ${TODAYPRETTY} | ${HTMLVER} |/g" README.md
git commit -am "Committing updated add-on releases." || { echo "Unable to commit."; }
git push origin
cd ..
rm -Rf "give-addon-releases"
echo ""

# REMOVE .GIT DIR AS WE'RE DONE WITH GIT
cd "$ROOT_PATH$TEMP_GITHUB_REPO"
rm -Rf .git
sleep 3
clear

# Create the Zip File
echo "--------------------------------------------------"
echo "Creating zip package..."
echo "--------------------------------------------------"
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
echo ""
echo "--------------------------------------------------"
echo "Creatings readme.txt file for website:"
echo "--------------------------------------------------"
mv "$ROOT_PATH$TEMP_GITHUB_REPO"/readme.txt /tmp/
rm -rf "$ROOT_PATH$TEMP_GITHUB_REPO"
mkdir "$ROOT_PATH$PLUGIN_SLUG"
mv /tmp/readme.txt "$ROOT_PATH$PLUGIN_SLUG"
echo ""

# SECURE COPY FILES OVER TO GIVEWP.COM
#scp "$PLUGIN_SLUG".zip client_devin@54.156.11.193:/data/s828204/dom24402/dom24402/downloads/plugins LIVE
#scp "$PLUGIN_SLUG".zip client_devin@54.156.11.193:/data/s828204/dom24442/dom24442/downloads/plugins/ STAGING
echo "--------------------------------------------------"
read -rp "Are you ready to move the files to givewp.com?"
echo "--------------------------------------------------"
scp "$PLUGIN_SLUG".zip client_devin@54.156.11.193:/data/s828204/dom24402/dom24402/downloads/plugins
scp "$ROOT_PATH$PLUGIN_SLUG"/readme.txt client_devin@54.156.11.193:/data/s828204/dom24402/dom24402/downloads/plugins/"$PLUGIN_SLUG"
echo "Files transferred..."
echo ""


# CLEAR SUCURI WAF CACHE
echo ""
echo "--------------------------------------------------"
echo "Clearing Sucuri WAF cache for the Zip file"
echo "--------------------------------------------------"
curl 'https://waf.sucuri.net/api?v2' \
--data 'k=' \
--data 's=' \
--data 'a=clear_cache' \
--data "file=$ROOT_PATH$PLUGIN_SLUG.zip"
echo ""

# CLEAR SUCURI WAF CACHE
echo ""
echo "--------------------------------------------------"
echo "Clearing Sucuri WAF cache for the Readme file"
echo "--------------------------------------------------"
curl 'https://waf.sucuri.net/api?v2' \
--data 'k=' \
--data 's=' \
--data 'a=clear_cache' \
--data "file=$ROOT_PATH$PLUGIN_SLUG/readme.txt"
echo ""

echo ""
echo "--------------------------------------------------"
echo "Cleaning up the directory..."
echo "--------------------------------------------------"
rm -Rf "$ROOT_PATH$TEMP_GITHUB_REPO"
echo ""


# DONE, BYE
echo "--------------------------------------------------"
echo "Releaser done!"
echo "--------------------------------------------------"
echo "What's left? Update the version number in EDD and publish the draft tag in the GitHub repository!"
