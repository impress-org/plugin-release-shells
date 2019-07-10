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
echo "      Github Test ZIP extractor             "
echo "--------------------------------------------"
read -p "CREATE ZIP OF VERSION: " VERSION
read -p "Send to GDrive? (type y or n):" DRIVE
echo "--------------------------------------------"
echo ""
echo "Before continuing, confirm that you have done the following :)"
echo ""
read -p " - Committed all changes up to GITHUB?"
echo ""
read -p "PRESS [ENTER] TO PULL GITHUB REPO INTO TEMPORARY DIRECTORY "${VERSION}
clear

# VARS
ROOT_PATH=$(pwd)"/"
TEMP_GITHUB_REPO=${PLUGIN_SLUG}
GIT_REPO="https://github.com/"${GITHUB_REPO_OWNER}"/"${GITHUB_REPO_NAME}".git"

# DELETE OLD TEMP DIRS
rm -Rf  $TEMP_GITHUB_REPO

# CLONE GIT DIR
echo "Cloning GIT repository from GITHUB"
git clone --progress $GIT_REPO $TEMP_GITHUB_REPO || { echo "Unable to clone repo."; exit 1; }

# MOVE INTO GIT DIR
cd "$ROOT_PATH$TEMP_GITHUB_REPO"

# LIST BRANCHES
clear
git fetch origin
echo "WHICH BRANCH DO YOU WISH TO ZIP?"
git branch -r || { echo "Unable to list branches."; exit 1; }
echo ""
read -p "origin/" BRANCH

# SWITCH TO BRANCH
echo "Switching to branch"
git checkout ${BRANCH} || { echo "Unable to checkout branch."; exit 1; }
echo ""
read -p "PRESS [ENTER] TO PREPARE LOCAL BRANCH FOR ZIPPING"

# RUN COMPOSER
composer install
# npm cache verify
npm install cross-env
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
rm -f sample-data/sample-data.numbers
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
rm -f docker-compose.yml

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


read -p "PRESS ENTER TO CREATE ZIP OF VERSION "${VERSION}
zip -r ../give.zip *
cd ..

# TODO: make sure this path works for Windows machines.
mv give.zip ~/Desktop/give.zip

if [ ${DRIVE} = "y" ]; then
    cd ~/Desktop
    read -p "PRESS ENTER TO COPY ZIP TO GOOGLE DRIVE"
# TODO: make this path something more universal.
# It currently only works on my machine to copy something to Drive
    cp give.zip /Volumes/GoogleDrive/My\ Drive/IMPRESS/SUPPORT\ TEAM/PLUGINS/give.zip
fi

# REMOVE THE TEMP DIRS
read -p "Ready to clean up?"
echo "CLEANING UP"
cd "$ROOT_PATH$TEMP_GITHUB_REPO"
rm -Rf "$ROOT_PATH$TEMP_GITHUB_REPO"

# DONE, BYE
# TODO: modify language here to let people know whether the upload to the cloud was successful.
echo "ZIPper DONE. The file is on your desktop :D"
