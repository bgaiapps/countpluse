# Countpluse - Google Play Store Launch Plan

## Phase 1: Pre-Launch Preparation (Week 1-2)

### 1.1 App Configuration & Metadata
- [ ] Update `pubspec.yaml` with final version number (currently check version)
- [ ] Set minimum SDK version (currently check in `android/app/build.gradle.kts`)
- [ ] Update app name in `android/app/src/main/AndroidManifest.xml`
- [ ] Add app description (2-4 sentence marketing copy)
- [ ] Prepare app icon (512x512 PNG for Play Store)
- [ ] Create 2-8 screenshots (1080x1920px) showing:
  - Home screen with counter
  - Summary analytics screen
  - Settings screen
  - Dark mode demonstration
- [ ] Write privacy policy (required for Play Store)
- [ ] Create end-user license agreement (EULA)

### 1.2 Backend Infrastructure Setup
- [ ] Deploy Node.js backend server to production hosting:
  - Options: AWS EC2, DigitalOcean, Heroku, Google Cloud Run
  - Recommended: Google Cloud Run (integrates well with Play Store)
- [ ] Move MongoDB to production database:
  - Options: MongoDB Atlas (cloud), AWS DocumentDB, Google Cloud Firestore
  - Recommended: MongoDB Atlas free tier or paid
- [ ] Set up environment variables for production
  - Update `FRONTEND_URL` in backend `.env`
  - Ensure `MONGODB_URI` points to production database
- [ ] Configure CORS for production domain
- [ ] Set up SSL/TLS certificates (HTTPS required)
- [ ] Test all API endpoints in production environment

### 1.3 App Code Updates
- [ ] Update backend API URLs in Flutter app (currently localhost:5001)
  - Create environment configuration for production URLs
  - File: `lib/services/app_state.dart` or new `lib/config/api_config.dart`
- [ ] Update package name to unique identifier:
  - Android: `android/app/build.gradle.kts`
  - Example: `com.bragopal.countpluse`
- [ ] Set application label:
  - `android/app/src/main/AndroidManifest.xml`
- [ ] Configure app version code and version name
- [ ] Add necessary permissions to `AndroidManifest.xml`:
  - Internet permission (already included)
  - Storage permissions if needed
  - Camera permissions if future feature

## Phase 2: Testing & Quality Assurance (Week 2-3)

### 2.1 Functional Testing
- [ ] Test all user flows on Android device/emulator:
  - User registration with valid/invalid email
  - Email verification flow
  - User login
  - Counting functionality
  - Dark mode toggle
  - Settings persistence
  - Data export feature
  - Sign out functionality
- [ ] Test offline functionality (if required)
- [ ] Test API error handling (network failures, invalid tokens)
- [ ] Test on multiple Android versions (minimum SDK to latest)

### 2.2 Performance Testing
- [ ] Check app startup time
- [ ] Memory usage profiling
- [ ] Battery consumption analysis
- [ ] Network request optimization

### 2.3 Security Review
- [ ] Audit JWT token handling
- [ ] Review password hashing (bcryptjs)
- [ ] Check for hardcoded secrets/credentials
- [ ] Validate HTTPS usage for all API calls
- [ ] Ensure sensitive data not logged

### 2.4 Compliance Check
- [ ] Verify privacy policy completeness
- [ ] Ensure GDPR compliance (if applicable)
- [ ] Check age rating requirements
- [ ] Verify ad/payment disclosure (if applicable)

## Phase 3: Build & Signing (Week 3)

### 3.1 Generate Signing Key
```bash
# Create keystore file (run once, save securely)
keytool -genkey -v -keystore ~/countpluse-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias countpluse-key
```
- [ ] Save keystore file securely (backup in multiple locations)
- [ ] Document password securely
- [ ] Store alias and key password

### 3.2 Configure Signing in Gradle
- [ ] Update `android/app/build.gradle.kts` with signing config:
  ```kotlin
  signingConfigs {
    release {
      keyAlias = 'countpluse-key'
      keyPassword = 'YOUR_KEY_PASSWORD'
      storeFile = file('path/to/countpluse-key.jks')
      storePassword = 'YOUR_STORE_PASSWORD'
    }
  }
  buildTypes {
    release {
      signingConfig = signingConfigs.release
    }
  }
  ```

### 3.3 Build Release AAB (Android App Bundle)
```bash
cd /Users/bragopal/Downloads/countpluse
flutter build appbundle --release
```
- [ ] Output file: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Verify build completes without errors
- [ ] Test AAB file integrity

### 3.4 Build Debug APK (for testing)
```bash
flutter build apk --release
```
- [ ] Install on test devices to verify functionality
- [ ] Test all features on real hardware

## Phase 4: Google Play Store Setup (Week 3)

### 4.1 Create Developer Account
- [ ] Go to [Google Play Console](https://play.google.com/console)
- [ ] Sign in with Google account
- [ ] Pay one-time $25 registration fee
- [ ] Accept agreements and policies
- [ ] Complete account setup

### 4.2 Create App Listing
- [ ] Create new app in Play Console
- [ ] Select "Countpluse" as app name
- [ ] Choose default language (English)
- [ ] Select app category (Productivity, Utilities, Health & Fitness)
- [ ] Provide contact email

### 4.3 Fill in App Details
- [ ] App name (50 chars max)
- [ ] Short description (80 chars max)
- [ ] Full description (4000 chars max)
- [ ] Upload app icon (512x512 PNG)
- [ ] Upload feature graphic (1024x500 PNG)
- [ ] Upload 2-8 screenshots (1080x1920px each)
- [ ] Optional: Upload preview video (up to 30 seconds)

### 4.4 Content Rating
- [ ] Complete Content Rating Questionnaire
- [ ] Get rating classification (Everyone, Teen, Mature, etc.)

### 4.5 Privacy & Permissions
- [ ] Upload privacy policy URL
- [ ] Declare data collection and usage
- [ ] Review requested permissions
- [ ] Select app target audience

### 4.6 Pricing & Distribution
- [ ] Select free or paid
- [ ] Choose countries/regions
- [ ] Set release date (immediate or scheduled)

## Phase 5: Submission & Review (Week 4)

### 5.1 Upload Build
- [ ] Go to Release > Production in Play Console
- [ ] Upload `app-release.aab` file
- [ ] Review build information
- [ ] Verify version number and requirements

### 5.2 Pre-Submission Checklist
- [ ] All required fields completed
- [ ] Privacy policy linked and accessible
- [ ] No hardcoded test links or credentials
- [ ] App functions as described
- [ ] Content rating appropriate
- [ ] All graphics uploaded (icon, screenshots, feature image)

### 5.3 Submit for Review
- [ ] Click "Submit" in Play Console
- [ ] Review appears as "Pending publication"
- [ ] Wait for Google Play Review Team (typically 2-4 hours, up to 7 days)

### 5.4 Handle Review Feedback
- [ ] Monitor review status in Play Console
- [ ] If rejected, read rejection reason carefully
- [ ] Fix any issues and resubmit
- [ ] Common rejection reasons:
  - Broken functionality
  - Misleading description
  - Privacy policy violations
  - Permissions not justified

## Phase 6: Post-Launch (Week 4+)

### 6.1 Monitor & Support
- [ ] Monitor crash reports in Play Console
- [ ] Read user reviews
- [ ] Respond to user feedback professionally
- [ ] Track install and uninstall rates

### 6.2 Update & Maintenance Plan
- [ ] Set schedule for regular updates
- [ ] Monitor API backend logs
- [ ] Fix critical bugs immediately
- [ ] Plan feature updates quarterly

### 6.3 Marketing
- [ ] Share app link on social media
- [ ] Request reviews from users
- [ ] Consider app store optimization (ASO)
- [ ] Monitor download trends

### 6.4 Analytics Setup
- [ ] Integrate Google Analytics for Flutter
- [ ] Track user retention
- [ ] Monitor feature usage
- [ ] Identify performance bottlenecks

## Critical Checklist Before Submission

- [ ] Backend API is accessible and stable (HTTPS)
- [ ] All API endpoints tested and working
- [ ] App icon and screenshots are high quality
- [ ] Privacy policy is clear and accurate
- [ ] No debug logging or test code in release build
- [ ] Minimum Android SDK version set appropriately
- [ ] App target SDK version is current (API 34+)
- [ ] No hardcoded credentials or secrets
- [ ] All permissions justified in description
- [ ] Battery and network optimization done
- [ ] No crashes on test devices
- [ ] Dark mode working correctly
- [ ] Settings persist after app restart
- [ ] Offline handling appropriate

## File Checklist

### Flutter App Files to Verify
- [ ] `pubspec.yaml` - version number updated
- [ ] `android/app/build.gradle.kts` - version code/name, package name
- [ ] `android/app/src/main/AndroidManifest.xml` - permissions, app label
- [ ] `lib/main.dart` - API URL environment-specific
- [ ] `lib/services/` - no hardcoded test URLs

### Required Assets
- [ ] App icon (512x512 PNG) - `android/app/src/main/res/mipmap-*`
- [ ] Screenshots (1080x1920 PNG) - 2-8 images
- [ ] Feature graphic (1024x500 PNG)
- [ ] Privacy policy document
- [ ] EULA document

## Timeline Summary
- **Week 1-2**: Preparation & configuration
- **Week 2-3**: Testing & quality assurance
- **Week 3**: Build & signing
- **Week 3**: Google Play Store setup
- **Week 4**: Submission & review
- **Week 4+**: Launch & post-launch monitoring

## Next Steps
1. Start with Phase 1.1 - Update app metadata
2. Deploy backend to production
3. Update API URLs in Flutter app
4. Execute comprehensive testing
5. Generate signing key and build release
6. Set up Google Play Console
7. Submit for review

---
**Last Updated**: February 3, 2026
**Status**: Ready for implementation
