# Countpluse

Countpluse is a devotional japa counter built with Flutter. It supports guest
and login flows, daily counting, summaries, voice-assisted counting, and
customizable practice settings such as daily goal, mantra label, profile photo,
and wallpaper.

## Android Release Notes

Android release configuration is ready in the repo:

- package id: `com.bgaiapps.countpluse`
- app label: `Countpluse`
- launcher icon source: `assets/logo.png`
- release signing template: `android/key.properties.example`

Before building a Play Store release, create:

- `android/key.properties`
- your upload keystore file (`.jks` / `.keystore`)

Then build:

```bash
flutter build appbundle --release
```

Output:

- `build/app/outputs/bundle/release/app-release.aab`

## Launcher Icons

Regenerate launcher icons after updating `assets/logo.png`:

```bash
dart run flutter_launcher_icons
```

## App Store Documents

Repo-managed Play submission docs:

- `PLAY_STORE_LISTING.md`
- `PRIVACY_POLICY.md`
- `EULA.md`

## Development

Run Flutter locally:

```bash
flutter run
```

Run checks:

```bash
flutter analyze
flutter test
```
