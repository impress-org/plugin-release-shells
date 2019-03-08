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
rm -Rf .git

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

echo "All Set, broseph"