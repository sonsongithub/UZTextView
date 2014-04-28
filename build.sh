xcodebuild -sdk iphoneos -arch armv7 -arch armv7s -arch arm64 clean build
xcodebuild -sdk iphonesimulator -arch i386 -arch x86_64 clean build

xcrun lipo -create build/Release-iphonesimulator/libUZTextView.a build/Release-iphoneos/libUZTextView.a -output build/libUZTextView.a
cp ./UZTextView/UZTextView.h ./build/
