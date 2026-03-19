# Countpluse Play Console Prep

Last updated: March 19, 2026

This file captures the recommended Play Console choices that can be prepared
from the current app behavior and repo state.

## 1. Recommended App Category

Primary recommendation:

- `Health & Fitness`

Why:

- The app supports devotional daily practice and habit-style tracking.
- The summary and daily goal flows fit better under routine/practice tracking
  than general utilities.

Secondary fallback:

- `Lifestyle`

Avoid unless your positioning changes:

- `Productivity`

## 2. Support / Contact Email

Recommended pattern:

- use a dedicated support email, not a personal inbox
- example: `support@countpluse.com`

If you do not have a custom domain yet, use a stable support mailbox that you
control and plan to keep long-term.

Avoid:

- temporary inboxes
- personal addresses you may later stop using

## 3. Countries / Regions

Recommended launch path:

- start with a smaller rollout first if this is the first Play release
- use internal testing or closed testing before broad production rollout

Suggested initial target:

- countries where you can actively support users and monitor OTP delivery
- if you want a simple first pass, launch in your primary support region first,
  then expand after successful OTP and device testing

## 4. Data Safety Draft

This is guidance only. Final answers must be confirmed in Play Console.

### Data Collected

Likely yes:

- Personal info
  - name
  - email address
  - phone number
- App activity / user-generated app data
  - devotional counting data
  - settings choices such as target label, goal, optional profile/wallpaper use

Likely no:

- precise location
- financial info
- health records in the regulated/medical sense
- contacts
- messages
- web browsing history

### Data Shared

Likely answer:

- No, user data is not sold or shared for advertising

Operational note:

- Service providers may process data for backend, database, and email delivery,
  but that is generally handled as service processing rather than advertising
  sharing

### Data Processing Purpose

Likely purposes to declare:

- app functionality
- account management
- security / fraud prevention / authentication

Do not claim purposes you are not actually using, such as:

- advertising
- personalization for ads

### Security

Likely yes:

- data is transmitted over HTTPS in production
- users can request account-based actions via support once your support flow is
  defined

## 5. Content Rating Guidance

Most likely rating outcome:

- `Everyone`

Reasoning:

- devotional counting app
- no gambling
- no violence
- no sexual content
- no user-to-user public content

When answering the questionnaire, keep answers aligned with the actual app:

- no mature content
- no random chat/social platform
- no paid gambling

## 6. Permissions Notes For Play Review

`INTERNET`

- required for login, registration, OTP verification, and backend sync

`RECORD_AUDIO`

- used only for optional voice-assisted counting

`CAMERA`

- used only when the user chooses to capture a profile photo or wallpaper image

## 7. Recommended Submission Sequence

1. Enable GitHub Pages and confirm the privacy policy URL.
2. Finish production backend deployment and test OTP on the real production URL.
3. Upload the signed AAB to internal testing first.
4. Complete Data safety and Content rating using this guide.
5. Add screenshots and feature graphic.
6. Promote to production after internal validation.
