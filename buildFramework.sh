BUILD_DIR="./Build"
DEVICE_DIR="$BUILD_DIR/device"
SIMULATOR_DIR="$BUILD_DIR/simulator"
UNIVERSAL_DIR="$BUILD_DIR/universal"
PROJECT_NAME="EbsSDK"
VERSION=$1

xcodebuild  -project  "$PROJECT_NAME.xcodeproj"  -scheme "EbsSDK"  -configuration  Release -sdk  iphoneos        ONLY_ACTIVE_ARCH=NO CONFIGURATION_BUILD_DIR="$DEVICE_DIR/"    clean build
xcodebuild  -project  "$PROJECT_NAME.xcodeproj"  -scheme "EbsSDK"  -configuration  Release -sdk  iphonesimulator ONLY_ACTIVE_ARCH=NO CONFIGURATION_BUILD_DIR="$SIMULATOR_DIR/" clean build

mkdir $UNIVERSAL_DIR

cp -R "$DEVICE_DIR/." "$UNIVERSAL_DIR/"
cp -R  "$SIMULATOR_DIR/EbsSDK.framework/Modules/EbsSDK.swiftmodule/." "$UNIVERSAL_DIR/EbsSDK.framework/Modules/EbsSDK.swiftmodule"
lipo -create -output "$UNIVERSAL_DIR/EbsSDK.framework/EbsSDK" "$DEVICE_DIR/EbsSDK.framework/EbsSDK" "$SIMULATOR_DIR/EbsSDK.framework/EbsSDK"
lipo -create -output "$UNIVERSAL_DIR/EbsSDK.framework.dSYM/Contents/Resources/DWARF/EbsSDK" "$DEVICE_DIR/EbsSDK.framework.dSYM/Contents/Resources/DWARF/EbsSDK" "$SIMULATOR_DIR/EbsSDK.framework.dSYM/Contents/Resources/DWARF/EbsSDK"

zip -r "./$PROJECT_NAME.$VERSION.zip" $BUILD_DIR
