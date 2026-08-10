# ── Credence Makefile ──
# All targets read secrets from .env via --dart-define-from-file.

ENV_FILE := .env
IOS_DEVICE_ID ?= 00008130-000164EC1ED1001C

# ─── Development ───────────────────────────────────────────────

.PHONY: run
run: ## Run debug on default device
	flutter run --dart-define-from-file=$(ENV_FILE)

.PHONY: run-macos
run-macos: ## Run debug on macOS
	flutter run -d macos --dart-define-from-file=$(ENV_FILE)

.PHONY: run-chrome
run-chrome: ## Run debug on Chrome
	flutter run -d chrome --dart-define-from-file=$(ENV_FILE)

.PHONY: run-ios
run-ios: ## Run debug on iOS simulator
	flutter run -d iphone --dart-define-from-file=$(ENV_FILE)

.PHONY: run-android
run-android: ## Run debug on Android
	flutter run -d android --dart-define-from-file=$(ENV_FILE)

# ─── Release ───────────────────────────────────────────────────

.PHONY: release
release: ## Run release on iOS device
	flutter run -d $(IOS_DEVICE_ID) --release --dart-define-from-file=$(ENV_FILE)

.PHONY: release-macos
release-macos: ## Run release on macOS
	flutter run -d macos --release --dart-define-from-file=$(ENV_FILE)

.PHONY: release-ios
release-ios: ## Run release on iOS device
	flutter run -d $(IOS_DEVICE_ID) --release --dart-define-from-file=$(ENV_FILE)

.PHONY: release-android
release-android: ## Run release on Android device
	flutter run -d android --release --dart-define-from-file=$(ENV_FILE)

# ─── Build ─────────────────────────────────────────────────────

.PHONY: build-apk
build-apk: ## Build release APK
	flutter build apk --release --dart-define-from-file=$(ENV_FILE)

.PHONY: build-appbundle
build-appbundle: ## Build release App Bundle (Play Store)
	flutter build appbundle --release --dart-define-from-file=$(ENV_FILE)

.PHONY: build-ios
build-ios: ## Build release iOS (archive)
	flutter build ios --release --dart-define-from-file=$(ENV_FILE)

.PHONY: build-ipa
build-ipa: ## Build release IPA (App Store)
	flutter build ipa --release --dart-define-from-file=$(ENV_FILE)

.PHONY: build-macos
build-macos: ## Build release macOS app
	flutter build macos --release --dart-define-from-file=$(ENV_FILE)

.PHONY: build-web
build-web: ## Build release web
	flutter build web --release --dart-define-from-file=$(ENV_FILE)

# ─── Quality ───────────────────────────────────────────────────

.PHONY: analyze
analyze: ## Run Flutter analyzer
	flutter analyze lib/

.PHONY: test
test: ## Run all tests
	flutter test

.PHONY: clean
clean: ## Clean build artifacts
	flutter clean && flutter pub get

# ─── Help ──────────────────────────────────────────────────────

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
