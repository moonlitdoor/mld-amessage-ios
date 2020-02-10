#!/bin/bash

#Color variables
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`


WORKSPACE="mobile.xcworkspace"
#Default values for user changable options
SCHEME="wealth"
# CONFIGURATION="Debug"
CONFIGURATION="Release"
XCCONFIG="./DebugConfig.xcconfig"
# XCCONFIG="./ReleaseCandidateConfig.xcconfig"
# FASTLANE_ENV="release-candidate"
FASTLANE_ENV="develop"
EXPORT_OPTIONS="./exportOptions-release_candidate.plist"


# Archive and Export Paths - set by default no user interaction
DERIVED_DATA_PATH="Build/data"
ARCHIVE_PATH_ROOT="$HOME/Library/Developer/Xcode/Archives"
ARCHIVE_PATH_SPECIFIC=$(date "+%Y-%m-%d/mobile-%Y-%m-%d-%H.%M.%S")

ARCHIVE_PATH="$ARCHIVE_PATH_ROOT/$ARCHIVE_PATH_SPECIFIC.xcarchive"

EXPORT_PATH="$ARCHIVE_PATH_ROOT/tmp/"

# Build script comand options
DEBUG=false
PODS=true
MATCH=true
RUN_TESTS=true
UPLOAD=true
EXPORT=true
BUILD=true

while [ "$1" != "" ]; do
    case $1 in
        -d  | --debug )     DEBUG=true ;;
		-np | --no-pods )   PODS=false ;;
		-nm | --no-match )  MATCH=false ;;
        -nt | --no-tests )  RUN_TESTS=false ;;
		-nu | --no-upload ) UPLOAD=false ;;
		-ne | --no-export ) EXPORT=false ;;
		-nb | --no-build )  BUILD=false ;;
		-s  | --scheme )    shift ; SCHEME=$1 ;;
		-c  | --config )    shift ; CONFIGURATION=$1 ;;
		-xc | --xcconfig )  shift ; XCCONFIG=$1 ;;
		-e  | --env )       shift ; FASTLANE_ENV=$1 ;;
		-o  | --options )   shift ; EXPORT_OPTIONS=$1 ;;
		-w  | --workspace ) shift ; WORKSPACE=$1 ;;
        * )        			echo "Invalid argument $1" ; exit 1
    esac
    shift
done

trap '{ echo "${red}*** Exiting. ***${reset}" ; exit 1; }' INT

function debug_output () {
	if $DEBUG ; then 
		echo "${red}WORKSPACE ** $WORKSPACE 
SCHEME    ** $SCHEME 
CONFIGURATION ** $CONFIGURATION 
XCCONFIG ** $XCCONFIG 
FASTLANE_ENV ** $FASTLANE_ENV 
EXPORT_OPTIONS ** $EXPORT_OPTIONS 
DERIVED_DATA_PATH ** $DERIVED_DATA_PATH 
ARCHIVE_PATH ** $ARCHIVE_PATH 
EXPORT_PATH ** $EXPORT_PATH 
${reset}"
	fi
}

function build_app () {
	echo "${green}*** Compiling Application ***${reset}"
	status=$(set -o pipefail && xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration "$CONFIGURATION" -xcconfig "$XCCONFIG" -destination 'generic/platform=iOS' -archivePath "$ARCHIVE_PATH" -derivedDataPath "$DERIVED_DATA_PATH" OBJROOT=./Build/ archive -useNewBuildSystem="True" -quiet )
	exit_code=$?
	if [ $exit_code -ne 0 ] 
		then
			echo "${red}***** Build Faild - ${exit_code} - ${FUNCNAME[0]} *****${reset}"
			exit $exit_code
	fi
	echo "$status"
	echo "${green}*** Finished Compiling Application ***${reset}"
}

function export_ipa () {
	echo "${green}*** Exporting IPA ***${reset}"
	mkdir "$EXPORT_PATH"
	xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportOptionsPlist "$EXPORT_OPTIONS" -exportPath "$EXPORT_PATH"
	exit_code=$?
	if [ $exit_code -ne 0 ] 
		then
			echo "${red}***** Build Faild - ${exit_code} - ${FUNCNAME[0]} *****${reset}"
			exit $exit_code
	fi
	echo "${green}*** Finished Exporting IPA ***${reset}"
}

function test_app () {
	echo "${green}*** Testing App ***${reset}"
	xcodebuild test-without-building -archivePath "$ARCHIVE_PATH" -scheme "wealth" -destination 'platform=iOS Simulator,name=iPhone Xs,OS=12.0' -derivedDataPath "$DERIVED_DATA_PATH"
	exit_code=$?
	if [ $exit_code -ne 0 ] 
		then
			echo "${red}***** Build Faild - ${exit_code} - ${FUNCNAME[0]} *****${reset}"
			exit $exit_code
	fi
	echo "${green}*** Finished Testing App ***${reset}"
}

function upload_apple () {
	altool="$(dirname "$(xcode-select -p)")/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool"
	exit_code=$?
	if [ $exit_code -ne 0 ] 
		then
			echo "${red}***** Build Faild - ${exit_code} - ${FUNCNAME[0]} *****${reset}"
			exit $exit_code
	fi
}

function upload_crashlytics () {
	local IPA_PATH="$EXPORT_PATH""wealth.ipa"
	echo "${green}*** Preparing to upload ipa at $IPA_PATH to Crashlytics ***${reset}"
	
	status=$(( eval ./Pods/Crashlytics/submit 2ee7506b7ba91b67829951a25fb0fc59e889b361 5f845bd3e282d16d8a22e0e96aede7947a2fed336fbd4fa2cc5a759778027548 -ipaPath $IPA_PATH ; ) &)
	wait
	echo "$status"
	echo "Finished"
}

#
## ---- MAIN ----
#
debug_output

if $PODS ; then
	echo "${green}*** Running Pod Install ***${reset}"
	bundle exec pod install --silent
	exit_code=$?
	if [ $exit_code -ne 0 ] 
		then
			echo "${red}***** Build Faild - ${exit_code} - ${FUNCNAME[0]} *****${reset}"
			exit $exit_code
	fi
fi

if $MATCH ; then
	echo "${green}*** Running fastlane match ***${reset}"
	bundle exec fastlane testEnv --env "$FASTLANE_ENV"
	exit_code=$?
	if [ $exit_code -ne 0 ] 
		then
			echo "${red}***** Build Faild - ${exit_code} - ${FUNCNAME[0]} *****${reset}"
			exit $exit_code
	fi
fi

if $BUILD ; then
	build_app
fi

if $RUN_TESTS ; then
	test_app
fi

if $EXPORT ; then
	export_ipa
fi

if $UPLOAD ; then
	upload_crashlytics
fi
