xcodebuild -sdk iphoneos -arch armv7 -arch armv7s clean build
xcodebuild -sdk iphonesimulator -arch i386 clean build

mkdir -p ./Product
xcrun lipo -create build/Release-iphonesimulator/libUZTextView.a build/Release-iphoneos/libUZTextView.a -output Product/libUZTextView.a
cp ./UZTextView/UZTextView.h ./Product/

if [ -x /usr/local/bin/appledoc ]; then
	echo "appledoc is found and executable, will start to create documentation."
	appledoc --project-name UZTextView --project-company sonson --create-html --no-create-docset --no-repeat-first-par --output ./Product/ ./UZTextView/
	rm -rf ./Product/document
	mv ./Product/html ./Product/document
else
	echo "appledoc is not found"
fi
