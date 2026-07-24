APP_NAME = Zobáčik
APP = build/$(APP_NAME).app

.PHONY: app test clean

app:
	swift build -c release
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS"
	cp .build/release/Zobacik "$(APP)/Contents/MacOS/Zobacik"
	cp Info.plist "$(APP)/Contents/Info.plist"
	strip -x "$(APP)/Contents/MacOS/Zobacik"
	xattr -cr "$(APP)"
	codesign --force --sign - "$(APP)"
	@echo "Built $(APP)"

test:
	swift test

clean:
	swift package clean
	rm -rf build
