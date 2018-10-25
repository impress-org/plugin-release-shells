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

# The slug of your WordPress.org plugin
PLUGIN_SLUG="give"

# GITHUB user who owns the repo
GITHUB_REPO_OWNER="impress-org"

# GITHUB Repository name
GITHUB_REPO_NAME="give"

# ----- STOP EDITING HERE -----

set -e
clear

# ASK INFO
echo "--------------------------------------------"
echo "      Github to WordPress.org RELEASER      "
echo "--------------------------------------------"
read -p "TAG AND RELEASE VERSION: " VERSION
echo "--------------------------------------------"
echo ""
echo "Before continuing, confirm that you have done the following :)"
echo ""
read -p " - Added a changelog for "${VERSION}"?"
read -p " - Set version in the readme.txt and main file to "${VERSION}"?"
read -p " - Set stable tag in the readme.txt file to "${VERSION}"?"
read -p " - Updated the POT file?"
read -p " - Committed all changes up to GITHUB?"
echo ""
read -p "PRESS [ENTER] TO BEGIN RELEASING "${VERSION}
clear

# VARS
ROOT_PATH=$(pwd)"/"
TEMP_GITHUB_REPO=${PLUGIN_SLUG}"-git"
TEMP_SVN_REPO=${PLUGIN_SLUG}"-svn"
SVN_REPO="http://plugins.svn.wordpress.org/"${PLUGIN_SLUG}"/"
GIT_REPO="git@github.com:"${GITHUB_REPO_OWNER}"/"${GITHUB_REPO_NAME}".git"

# DELETE OLD TEMP DIRS
rm -Rf  $TEMP_GITHUB_REPO
# rm -Rf $TEMP_SVN_REPO

# CHECKOUT SVN DIR IF NOT EXISTS
if [[ ! -d $TEMP_SVN_REPO ]];
then
	echo "Checking out WordPress.org plugin repository"
	svn checkout $SVN_REPO $TEMP_SVN_REPO || { echo "Unable to checkout repo."; exit 1; }
fi

# CLONE GIT DIR
echo "Cloning GIT repository from GITHUB"
git clone --progress $GIT_REPO $TEMP_GITHUB_REPO || { echo "Unable to clone repo."; exit 1; }

# MOVE INTO GIT DIR
cd "$ROOT_PATH$TEMP_GITHUB_REPO"

# LIST BRANCHES
clear
git fetch origin
echo "WHICH BRANCH DO YOU WISH TO DEPLOY?"
git branch -r || { echo "Unable to list branches."; exit 1; }
echo ""
read -p "origin/" BRANCH

# SWITCH TO BRANCH
echo "Switching to branch"
git checkout ${BRANCH} || { echo "Unable to checkout branch."; exit 1; }
echo ""
read -p "PRESS [ENTER] TO DEPLOY BRANCH "${BRANCH}

# RUN COMPOSER
composer install
npm install
npm run build

# REMOVE UNWANTED FILES & FOLDERS
echo "Removing unwanted files"
rm -Rf .git
rm -Rf tests
rm -Rf bower
rm -Rf vendor/squizlabs
rm -Rf vendor/wimg
rm -Rf vendor/wp-coding-standards
rm -Rf vendor/tecnickcom/tcpdf/examples
rm -Rf vendor/tecnickcom/tcpdf/tools
rm -Rf vendor/composer/installers
rm -Rf vendor/bin
rm -Rf tmp
rm -Rf node_modules
rm -Rf apigen
rm -Rf assets/src
rm -Rf .idea
rm -Rf .github

# Hidden Files
rm -f .bowerrc
rm -f .scrutinizer.yml
rm -f .travis.yml
rm -f .CONTRIBUTING.md
rm -f .gitattributes
rm -f .gitignore
rm -f .gitmodules
rm -f .editorconfig
rm -f .travis.yml
rm -f .babelrc
rm -f .jscrsrc
rm -f .jshintrc
rm -f .eslintignore
rm -f .eslintrc

# Other Files
rm -f sample-data/wordpress.sql
rm -f bower.json
rm -f composer.json
rm -f composer.lock
rm -f package.json
rm -f package-lock.json
rm -f composer.json
rm -f phpunit.xml
rm -f phpunit.xml.dist
rm -f CHANGELOG.md
rm -f README.md
rm -f readme.md
rm -f phpcs.ruleset.xml
rm -f CONTRIBUTING.md
rm -f CODE_OF_CONDUCT.md
rm -f contributing.md
rm -f postcss.config.js
rm -f webpack.config.js

# Delete un-used fonts
rm -rf includes/libraries/tcpdf/fonts/ae_fonts_2.0
rm -rf includes/libraries/tcpdf/fonts/dejavu-fonts-ttf-2.33
rm -rf includes/libraries/tcpdf/fonts/dejavu-fonts-ttf-2.34
rm -rf includes/libraries/tcpdf/fonts/freefont-20100919
rm -rf includes/libraries/tcpdf/fonts/freefont-20120503
rm -rf includes/libraries/tcpdf/fonts/freemon*
rm -rf includes/libraries/tcpdf/fonts/cid*
rm -rf includes/libraries/tcpdf/fonts/courier*
rm -rf includes/libraries/tcpdf/fonts/aefurat*
rm -rf includes/libraries/tcpdf/fonts/dejavusansb*
rm -rf includes/libraries/tcpdf/fonts/dejavusansi*
rm -rf includes/libraries/tcpdf/fonts/dejavusansmono*
rm -rf includes/libraries/tcpdf/fonts/dejavusanscondensed*
rm -rf includes/libraries/tcpdf/fonts/dejavusansextralight*
rm -rf includes/libraries/tcpdf/fonts/dejavuserif*
rm -rf includes/libraries/tcpdf/fonts/freesan*
rm -rf includes/libraries/tcpdf/fonts/pdf*
rm -rf includes/libraries/tcpdf/fonts/times*
rm -rf includes/libraries/tcpdf/fonts/uni2cid*

# MOVE INTO SVN DIR
cd "$ROOT_PATH$TEMP_SVN_REPO"

# UPDATE SVN
echo "Updating SVN"
svn update || { echo "Unable to update SVN."; exit 1; }

# DELETE TRUNK
echo "Replacing trunk"
rm -Rf trunk/

# COPY GIT DIR TO TRUNK
cp -R "$ROOT_PATH$TEMP_GITHUB_REPO" trunk/

# ADD FILES WITH "@" SYMBOL
# SEE: https://stackoverflow.com/questions/757435/how-to-escape-characters-in-subversion-managed-file-names
for file in $(find ./ -type f -name "*@*.png"); do
   svn add $file@ --force;
done

# DO THE ADD ALL NOT KNOWN FILES UNIX COMMAND
svn add --force * --auto-props --parents --depth infinity -q

# DO THE REMOVE ALL DELETED FILES UNIX COMMAND
MISSING_PATHS=$( svn status | sed -e '/^!/!d' -e 's/^!//' )

# iterate over filepaths
for MISSING_PATH in $MISSING_PATHS; do
    svn rm --force "$MISSING_PATH@"
done

# COPY TRUNK TO TAGS/$VERSION
echo "Copying trunk to new tag"
svn copy trunk tags/${VERSION} || { echo "Unable to create tag."; exit 1; }

# DO SVN COMMIT
clear
echo "Showing SVN status"
svn status

# PROMPT USER
echo ""
read -p "PRESS [ENTER] TO COMMIT RELEASE "${VERSION}" TO WORDPRESS.ORG"
echo ""

# DEPLOY
echo ""
echo "Committing to WordPress.org...this may take a while..."
svn commit -m "Release "${VERSION}", see readme.txt for changelog." || { echo "Unable to commit."; exit 1; }

# REMOVE THE TEMP DIRS
echo "CLEANING UP"
rm -Rf "$ROOT_PATH$TEMP_GITHUB_REPO"
rm -Rf "$ROOT_PATH$TEMP_SVN_REPO"

# DONE, BYE
echo "RELEASER DONE :D"