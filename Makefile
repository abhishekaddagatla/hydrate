APP_NAME = Hydrate
BUNDLE = build/$(APP_NAME).app
BINARY = build/$(APP_NAME)
SWIFT_FLAGS = -framework Cocoa -framework ServiceManagement -O

.PHONY: build install run clean

build:
	@mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	swiftc -o $(BINARY) Sources/WaterReminder.swift $(SWIFT_FLAGS)
	mv $(BINARY) $(BUNDLE)/Contents/MacOS/WaterReminder
	cp Resources/Info.plist $(BUNDLE)/Contents/
	cp Resources/applet.icns $(BUNDLE)/Contents/Resources/
	@echo "Built $(BUNDLE)"

install: build
	@mkdir -p ~/Applications
	rm -rf ~/Applications/$(APP_NAME).app
	cp -R $(BUNDLE) ~/Applications/
	@echo "Installed to ~/Applications/$(APP_NAME).app"

run: install
	open ~/Applications/$(APP_NAME).app

clean:
	rm -rf build
	@echo "Cleaned"
