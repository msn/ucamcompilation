#!/bin/bash

# Version configuration, this should match the appropriate value in:
# https://docs.google.com/a/caret.cam.ac.uk/spreadsheet/ccc?key=0AmhGGpAWvnFCdHEzRThtZ0ttZXR4V2NiWkRETXUwcWc&authkey=CJ-m3b8L&hl=en_GB&authkey=CJ-m3b8L
VERSION=`git describe`;

BUILD_STEP=${1};

if [ "${BUILD_STEP}" = "pre" ] ; then
    echo "INFO: Running pre flight check for version: ${VERSION}";
    CHECK_VERSION=`grep ${VERSION} pom.xml`;
    if [ "${?}" != "0" ] ; then
        echo "ERROR: Version \"${VERSION}\" not found in pom.xml, aborting!"
        exit 1;
    fi
else
    if [ "${BUILD_STEP}" = "post" ] ; then
        # Config / release jar:
        echo "INFO: Running post build setup for version: ${VERSION}";
        URL=release.caret.cam.ac.uk;
        # Copy OAE jar to release folder:
        echo "INFO: Making Ucam OAE release directory on ${URL}";
        ssh ${URL} "mkdir -p /var/www/${URL}/htdocs/ucamoae/";
        echo "INFO: Copying OAE release jar target/uk.ac.cam.caret.nakamura-${VERSION}.jar to /var/www/${URL}/htdocs/ucamoae/ on ${URL}";
        scp target/uk.ac.cam.caret.nakamura-${VERSION}.jar ${URL}:/var/www/${URL}/htdocs/ucamoae/;
        # Copy back end config across:
        if [ -d run/config ] ; then
          echo "INFO: Creating local config.tar.gz";
          tar czf config.tar.gz -C run config;
          echo "INFO: Making back end config directory /var/www/${URL}/htdocs/ucamoae/config/${VERSION} on ${URL}";
          ssh ${URL} "mkdir -p /var/www/${URL}/htdocs/ucamoae/config/${VERSION}";
          echo "INFO: Copying config.jar to /var/www/${URL}/htdocs/ucamoae/config/${VERSION} on ${URL}";
          scp config.tar.gz ${URL}:/var/www/${URL}/htdocs/ucamoae/config/${VERSION}/;
          echo "INFO: Removing local config file";
          rm -f config.tar.gz;
        fi

        # maven artifacts:
        NAME="uk/ac/cam/caret/nakamura/uk.ac.cam.caret.nakamura"
        URL="maven2.caret.cam.ac.uk"
        echo "INFO: Making directory /var/www/${URL}/htdocs/${NAME}/${VERSION} on ${URL}";
        ssh ${URL} "mkdir -p /var/www/${URL}/htdocs/${NAME}/${VERSION}";
        echo "INFO: Synching ~/.m2/repository/${NAME}/${VERSION} to ${URL}:/var/www/${URL}/htdocs/${NAME}/";
        rsync -av --delete ~/.m2/repository/${NAME}/${VERSION} ${URL}:/var/www/${URL}/htdocs/${NAME}/
    else
        echo "ERROR: Invalid build step: \"${BUILD_STEP}\" specified";
        echo "ERROR: Please use ${0} (pre|post)";
        exit 2;
    fi
fi

exit 0;
