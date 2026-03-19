# Countpluse Android Play Release Checklist

Last updated: March 19, 2026

This checklist tracks the remaining work needed to ship the current Android
version of Countpluse to Google Play.

## 1. Repo And Code Readiness

- [x] Create real Android upload keystore (`.jks` / `.keystore`)
- [x] Create `android/key.properties` from `android/key.properties.example`
- [x] Android package id set to `com.bgaiapps.countpluse`
- [x] Android app label set to `Countpluse`
- [x] Android release bundle builds successfully
- [x] Privacy policy draft created
- [x] EULA draft created
- [x] GitHub Pages HTML created for privacy policy
- [x] GitHub Pages HTML created for EULA
- [x] Push `docs/` pages to GitHub
- [ ] Enable GitHub Pages for `main` -> `/docs`
- [ ] Confirm final public privacy policy URL
- [x] Review Android permissions for release (`INTERNET`, `RECORD_AUDIO`, `CAMERA`)
- [x] Fix backend email regex mismatch
- [x] Add backend auth smoke/integration tests

## 2. Backend Production Readiness

- [ ] Finalize production backend host
- [ ] Finalize production MongoDB connection
- [ ] Confirm `API_BASE_URL` for production release build
- [ ] Verify production OTP email delivery
- [ ] Verify production CORS settings
- [ ] Confirm production env vars are complete
- [x] Confirm no secrets are hardcoded in tracked files

## 3. Store Assets

- [x] Final Play Store app icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Home screen screenshot
- [ ] Summary screen screenshot
- [ ] Settings screen screenshot
- [ ] Additional screenshots if needed

## 4. Store Listing

- [x] Draft short description prepared
- [x] Draft full description prepared
- [x] Play Console prep guide created
- [ ] Finalize support/contact email
- [ ] Finalize app category
- [ ] Finalize release countries/regions
- [ ] Finalize Data safety answers in Play Console
- [ ] Finalize Content rating questionnaire

## 5. Real Device Verification

- [ ] Test login with valid email
- [ ] Test login with invalid email
- [ ] Test registration with valid details
- [ ] Test registration validation errors
- [ ] Test OTP success flow
- [ ] Test OTP invalid flow
- [ ] Test counting flow
- [ ] Test reset confirmation flow
- [ ] Test summary screen
- [ ] Test settings updates
- [ ] Test profile photo flow
- [ ] Test wallpaper flow
- [ ] Test voice counting on a real Android device
- [ ] Test sign out flow
- [ ] Test release build for crashes

## 6. Final Submission Steps

- [x] Build signed release AAB with real upload key
- [ ] Upload AAB to Play Console internal testing or production
- [ ] Review Play Console warnings
- [ ] Attach privacy policy URL
- [ ] Attach screenshots and graphics
- [ ] Complete all required listing sections
- [ ] Submit for review

## Current Recommended Next Step

- [ ] Enable GitHub Pages for `main` -> `/docs`

## Notes

- `RECORD_AUDIO` stays in this release because Home includes the optional
  voice-counting feature.
- `CAMERA` stays in this release because Settings allows taking a profile photo
  and wallpaper photo directly from the camera.
- Play asset files currently prepared in `play-store-assets/`:
  - `app-icon-512.png`
  - `feature-graphic.svg`
  - `feature-graphic.svg.png` (preview export, not final Play upload file)
