MARKED_VER  = 11.1.1
HLJS_VER    = 11.8.0

APP_NAME     = MDViewer
BUNDLE_NAME  = $(APP_NAME).app
BUILD_DIR    = .build/release
BINARY       = $(BUILD_DIR)/$(APP_NAME)
SPM_BUNDLE   = $(BUILD_DIR)/$(APP_NAME)_$(APP_NAME).bundle
RESOURCES    = Sources/$(APP_NAME)/Resources

.PHONY: deps build bundle open run clean update-deps

deps:
	@mkdir -p $(RESOURCES)
	@echo "Downloading marked.js $(MARKED_VER)..."
	@curl -fsSL "https://unpkg.com/marked@$(MARKED_VER)/marked.min.js" \
		-o "$(RESOURCES)/marked.min.js"
	@echo "Downloading highlight.js $(HLJS_VER)..."
	@curl -fsSL "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/$(HLJS_VER)/highlight.min.js" \
		-o "$(RESOURCES)/highlight.min.js"
	@curl -fsSL "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/$(HLJS_VER)/styles/github-dark.min.css" \
		-o "$(RESOURCES)/highlight.min.css"
	@echo "Done."

build: $(RESOURCES)/marked.min.js
	swift build -c release

bundle: build
	@rm -rf $(BUNDLE_NAME)
	@mkdir -p $(BUNDLE_NAME)/Contents/MacOS
	@mkdir -p $(BUNDLE_NAME)/Contents/Resources
	@cp $(BINARY) $(BUNDLE_NAME)/Contents/MacOS/$(APP_NAME)
	@if [ -d "$(SPM_BUNDLE)" ]; then \
		cp -r "$(SPM_BUNDLE)" "$(BUNDLE_NAME)/Contents/Resources/"; \
	fi
	@cp Info.plist $(BUNDLE_NAME)/Contents/Info.plist
	@echo "Bundled: $(BUNDLE_NAME)"

open: bundle
	open $(BUNDLE_NAME)

run:
	swift run

clean:
	rm -rf .build $(BUNDLE_NAME)

update-deps:
	@rm -f $(RESOURCES)/marked.min.js \
		$(RESOURCES)/highlight.min.js \
		$(RESOURCES)/highlight.min.css
	@$(MAKE) deps
