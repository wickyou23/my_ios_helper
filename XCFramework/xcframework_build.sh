rm -rf "./build";



xcodebuild clean build archive \
-scheme TPAPReceiptLocally \
-configuration Release \
-sdk iphoneos \
-destination "generic/platform=iOS" \
-archivePath "${PWD}/build/ios-devices/TPAPReceiptLocally.framework-iphoneos.xcarchive" \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES;

#Remove this function when build objc framework
function GetUUID() {
    # dwarfdump output:
    # UUID: FFFFFFF-AAAAA-BBBB-CCCC-DDDDDDDDDD (arm64) PATH_TO_ARCHIVE/FRAMEWORK.framework-ios-arm64.xcarchive/Products/Library/Frameworks/FRAMEWORK.framework/FRAMEWORK
    local arch=$1
    local binary=$2
    local dwarfdump_result=$(dwarfdump -u ${binary})
    local regex="UUID: (.*) \((.*)\)"
    if [[ $dwarfdump_result =~ $regex ]]; then
        local result_uuid="${BASH_REMATCH[1]}"
        local result_arch="${BASH_REMATCH[2]}"
        if [ "$result_arch" == "$arch" ]; then
            echo $result_uuid
        fi
    fi
}

#Remove this line when build objc framework
BCSYMBOLMAP_UUID=$(GetUUID "arm64" "${PWD}/build/ios-devices/TPAPReceiptLocally.framework-iphoneos.xcarchive/Products/Library/Frameworks/TPAPReceiptLocally.framework/TPAPReceiptLocally")

#xcodebuild -create-xcframework \
#-framework "${PWD}/build/ios-devices/TPAPReceiptLocally.framework-iphoneos.xcarchive/Products/Library/Frameworks/TPAPReceiptLocally.framework" \
#-debug-symbols "${PWD}/build/ios-devices/TPAPReceiptLocally.framework-iphoneos.xcarchive/dSYMs/TPAPReceiptLocally.framework.dSYM" \
#-debug-symbols "${PWD}/build/ios-devices/TPAPReceiptLocally.framework-iphoneos.xcarchive/BCSymbolMaps/${BCSYMBOLMAP_UUID}.bcsymbolmap" \
#-output "${PWD}/build/ios-devices//TPAPReceiptLocally.xcframework";



xcodebuild archive \
-scheme TPAPReceiptLocally-Simulator \
-configuration Release \
-sdk iphonesimulator \
-destination "generic/platform=iOS" \
-archivePath "${PWD}/build/ios-simulator/TPAPReceiptLocally-Simulator.framework-iphoneos.xcarchive" \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES;

#xcodebuild -create-xcframework \
#-framework "${PWD}/build/ios-simulator/TPAPReceiptLocally-Simulator.framework-iphoneos.xcarchive/Products/Library/Frameworks/TPAPReceiptLocally_Simulator.framework" \
#-output "${PWD}/build/ios-simulator/TPAPReceiptLocally-Simulator.xcframework";



xcodebuild -create-xcframework \
-framework "${PWD}/build/ios-devices/TPAPReceiptLocally.framework-iphoneos.xcarchive/Products/Library/Frameworks/TPAPReceiptLocally.framework" \
-debug-symbols "${PWD}/build/ios-devices/TPAPReceiptLocally.framework-iphoneos.xcarchive/dSYMs/TPAPReceiptLocally.framework.dSYM" \
-debug-symbols "${PWD}/build/ios-devices/TPAPReceiptLocally.framework-iphoneos.xcarchive/BCSymbolMaps/${BCSYMBOLMAP_UUID}.bcsymbolmap" \ #Remove this line when build objc framework
-framework "${PWD}/build/ios-simulator/TPAPReceiptLocally-Simulator.framework-iphoneos.xcarchive/Products/Library/Frameworks/TPAPReceiptLocally_Simulator.framework" \
-output "${PWD}/build/ios-combine/TPAPReceiptLocally.xcframework";



#xcrun xcodebuild -create-xcframework \
#-framework "${PWD}/build/ios-devices/TPAPReceiptLocally.xcframework/ios-arm64/TPAPReceiptLocally.framework" \
#-framework "${PWD}/build/ios-simulator/TPAPReceiptLocally-Simulator.xcframework/ios-arm64_x86_64-simulator/TPAPReceiptLocally_Simulator.framework" \
#-output "${PWD}/build/ios-combine/TPAPReceiptLocally.xcframework"
