ZIP_NAME ?= "customDataTypeGetty.zip"
PLUGIN_NAME = "custom-data-type-getty"

# coffescript-files to compile
COFFEE_FILES = commons.coffee \
	CustomDataTypeGetty.coffee \
	CustomDataTypeGettyFacet.coffee \
	GettyUtil.coffee

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build ## build all

build: clean buildinfojson ## clean, compile, copy files to build folder

				npm install --save node-fetch # install needed node-module

				mkdir -p build
				mkdir -p build/$(PLUGIN_NAME)
				mkdir -p build/$(PLUGIN_NAME)/webfrontend
				mkdir -p build/$(PLUGIN_NAME)/updater
				mkdir -p build/$(PLUGIN_NAME)/l10n

				cp build-info.json build/$(PLUGIN_NAME)/build-info.json # build-info

				mkdir -p src/tmp # build code from coffee
				cp easydb-library/src/commons.coffee src/tmp
				cp src/webfrontend/*.coffee src/tmp
				cd src/tmp && coffee -b --compile ${COFFEE_FILES} # bare-parameter is obligatory!

				# first: commons! Important
				cat src/tmp/commons.js > build/$(PLUGIN_NAME)/webfrontend/customDataTypeGetty.js

				cat src/tmp/CustomDataTypeGetty.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypeGetty.js
				cat src/tmp/CustomDataTypeGettyFacet.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypeGetty.js
				cat src/tmp/GettyUtil.js >> build/$(PLUGIN_NAME)/webfrontend/customDataTypeGetty.js

				cp src/updater/GettyUpdater.js build/$(PLUGIN_NAME)/updater/GettyUpdater.js # build updater
				cat src/tmp/GettyUtil.js >> build/$(PLUGIN_NAME)/updater/GettyUpdater.js
				cp package.json build/$(PLUGIN_NAME)/package.json
				cp -r node_modules build/$(PLUGIN_NAME)/
				rm -rf src/tmp # clean tmp

				mkdir src/temp_localization
				cp l10n/customDataTypeGetty.csv src/temp_localization
				cp easydb-library/src/commons.l10n.csv src/temp_localization

				# equalize number of columns in localization csv files
				@file1=src/temp_localization/customDataTypeGetty.csv \
				file2=src/temp_localization/commons.l10n.csv \
				cols1=$$(head -n 1 $$file1 | awk -F',' '{print NF}'); \
				cols2=$$(head -n 1 $$file2 | awk -F',' '{print NF}'); \
				echo "File1 columns: $$cols1, File2 columns: $$cols2"; \
				if [ $$cols1 -lt $$cols2 ]; then \
					diff=$$((cols2 - cols1)); \
					echo "Padding $$file1 with $$diff empty columns..."; \
					commas=$$(printf '%.0s,' $$(seq 1 $$diff)); \
					sed -i "s/$$/$$commas/" $$file1; \
				elif [ $$cols2 -lt $$cols1 ]; then \
					diff=$$((cols1 - cols2)); \
					echo "Padding $$file2 with $$diff empty columns..."; \
					commas=$$(printf '%.0s,' $$(seq 1 $$diff)); \
					sed -i "s/$$/$$commas/" $$file2; \
				else \
					echo "Files already have equal columns."; \
				fi

				cp src/temp_localization/customDataTypeGetty.csv build/$(PLUGIN_NAME)/l10n/customDataTypeGetty.csv # copy l10n
				echo "" >> build/$(PLUGIN_NAME)/l10n/customDataTypeGetty.csv # add line break to make sure csv is not broken after merge
				tail -n+2 src/temp_localization/commons.l10n.csv >> build/$(PLUGIN_NAME)/l10n/customDataTypeGetty.csv 
				rm -rf src/temp_localization

				cp src/webfrontend/css/main.css build/$(PLUGIN_NAME)/webfrontend/customDataTypeGetty.css # copy css
				cp manifest.master.yml build/$(PLUGIN_NAME)/manifest.yml # copy manifest

clean: ## clean
				rm -rf build

zip: build ## build zip file
			cd build && zip ${ZIP_NAME} -r $(PLUGIN_NAME)/

buildinfojson:
	repo=`git remote get-url origin | sed -e 's/\.git$$//' -e 's#.*[/\\]##'` ;\
	rev=`git show --no-patch --format=%H` ;\
	lastchanged=`git show --no-patch --format=%ad --date=format:%Y-%m-%dT%T%z` ;\
	builddate=`date +"%Y-%m-%dT%T%z"` ;\
	echo '{' > build-info.json ;\
	echo '  "repository": "'$$repo'",' >> build-info.json ;\
	echo '  "rev": "'$$rev'",' >> build-info.json ;\
	echo '  "lastchanged": "'$$lastchanged'",' >> build-info.json ;\
	echo '  "builddate": "'$$builddate'"' >> build-info.json ;\
	echo '}' >> build-info.json
