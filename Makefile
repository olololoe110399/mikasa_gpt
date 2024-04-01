sync:
	flutter pub get && dart pub run build_runner build --delete-conflicting-outputs

watch:
	dart pub run build_runner watch --delete-conflicting-outputs