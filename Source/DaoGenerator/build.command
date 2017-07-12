DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 
cd "$DIR"

PROJECT='DaoGenerator'
PROJECT_PROJECT=$PROJECT'.xcodeproj'
CONFIGURATION='Release'
BUILD_PATH='Build'
SDK='macosx'

# BUILD

xcodebuild \
    -project $PROJECT_PROJECT \
    -configuration $CONFIGURATION \
    -sdk $SDK \
    CONFIGURATION_BUILD_DIR=$BUILD_PATH \
    CODE_SIGNING_REQUIRED=NO \
    OBJROOT=$(PWD)/build SYMROOT=$(PWD)/build \
    clean build
