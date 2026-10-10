# Setting up accounts and cloud proof photos

This adds real user accounts (email/password + Google) and moves proof
photos from local device storage into Firebase Storage, scoped per user.
Firebase was already wired into this project (`focuslock-bb239`), so most
of the plumbing is just turning features on in the console.

## 1. Install the new packages

```
flutter pub get
```

New dependencies added to `pubspec.yaml`: `firebase_auth`, `cloud_firestore`,
`firebase_storage`, `google_sign_in`.

## 2. Turn on sign-in methods in Firebase

Firebase Console → **Build → Authentication → Sign-in method**:
- Enable **Email/Password**.
- Enable **Google**. Set a support email when prompted.

## 3. Register your app's SHA-1/SHA-256 (Android, for Google Sign-In)

Google Sign-In on Android checks the app's signing fingerprint. Without
this step, Google sign-in will fail on Android with an error even though
email/password will still work fine.

```
cd android && ./gradlew signingReport
```

Copy the `SHA1` (and `SHA256`) for the `debug` variant, and later for your
release keystore too. Add them in Firebase Console → **Project settings →
Your apps → (Android app)** → "Add fingerprint". Then re-download
`google-services.json` and replace `android/app/google-services.json`.

Web and the current setup don't need this — Google sign-in on web uses
Firebase's built-in popup flow with no extra config.

## 4. iOS (only if you build for iOS)

This project doesn't currently have `ios/Runner/GoogleService-Info.plist`.
Run `flutterfire configure` (from the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup))
to generate it and register the iOS app, then add the reversed client ID
URL scheme to `ios/Runner/Info.plist` as the FlutterFire docs describe.

## 5. Turn on Firestore and Storage

Firebase Console → **Build → Firestore Database** → Create database (if not
already created). Same for **Build → Storage**.

## 6. Deploy the security rules

Two rules files are included at the project root:

- `firestore.rules` — a user can only read/write their own
  `users/{uid}/tasks/*` documents.
- `storage.rules` — a user can only read/write their own
  `users/{uid}/proofs/*` files, capped at 10 MB and images only.

Deploy with the Firebase CLI:

```
firebase deploy --only firestore:rules,storage:rules
```

(If you haven't used the Firebase CLI in this project before, run
`firebase init` first and point it at the existing `focuslock-bb239`
project — choose "use an existing project" rather than creating a new one.)

## What changed in the code

- **`lib/services/auth_service.dart`** / **`lib/providers/auth_provider.dart`** —
  sign up, sign in, Google sign-in, password reset, sign out.
- **`lib/screens/login_screen.dart`** — the sign-in/sign-up UI.
- **`lib/app.dart`** — `AuthGate` shows the login screen when signed out,
  the existing home screen when signed in.
- **`lib/services/firestore_task_service.dart`** — tasks now live in
  Firestore under `users/{uid}/tasks`, replacing the old
  `shared_preferences`-based `storage_service.dart` (removed).
- **`lib/providers/task_provider.dart`** — now streams from Firestore and
  re-binds automatically whenever the signed-in user changes (via
  `ChangeNotifierProxyProvider` in `main.dart`).
- **`lib/services/camera_service.dart`** — still opens the camera locally,
  but now uploads the photo to `users/{uid}/proofs/{taskId}.jpg` in
  Firebase Storage and returns a download URL.
- **`lib/models/task.dart`** — `proofImagePath` (local file path) replaced
  with `proofImageUrl` (Firebase Storage download URL).
- **`lib/screens/proof_screen.dart`** / **`lib/screens/history_screen.dart`** —
  show the local photo while it uploads, then the cloud URL afterward
  (`Image.network` instead of `Image.file`).
- **`lib/screens/settings_screen.dart`** — shows the signed-in account and
  a sign-out button.

## Notes / trade-offs

- Each device needs a network connection to load tasks and photos, since
  everything now lives in Firestore/Storage rather than on-device. Firestore
  does cache recent reads locally, so brief connectivity drops are fine.
- Deleting a task does not currently delete its uploaded proof photo from
  Storage — if you want that, delete `users/{uid}/proofs/{taskId}.jpg` in
  `FirestoreTaskService.deleteTask` (or a Cloud Function trigger) alongside
  the Firestore document.

## App blocking (Android)

Distraction-app blocking is now real, not a stub. It uses an
`AccessibilityService` that watches for the foreground app changing and, if
it's on the user's selected list, sends the device back to the home screen.

**A pre-existing bug fixed along the way:** `MainActivity.kt` declared
`package com.example.focus_lock` (with an underscore) while the app's actual
`applicationId`/`namespace` is `com.example.focuslock` (no underscore). That
mismatch would likely have broken the build or crashed on launch. It's now
corrected to `com.example.focuslock` throughout.

What was added:
- `FocusAccessibilityService.kt` — the service that does the blocking.
- `BlockerPrefs.kt` — a tiny native SharedPreferences bridge, since the
  Accessibility Service runs independently of the Flutter engine and can't
  receive MethodChannel calls directly. `MainActivity` writes to it when
  Flutter calls `startBlocking`/`stopBlocking`; the service reads from it.
- `res/xml/accessibility_service_config.xml` + a `<service>` entry in
  `AndroidManifest.xml` registering the service.
- `<queries>` entries in the manifest for the five candidate app package
  names (required for package visibility on Android 11+).
- `lib/models/distraction_app.dart` — the curated app list with real
  package names (TikTok, Facebook, Instagram, YouTube, Reddit).
- `lib/providers/blocked_apps_provider.dart` — persists the user's
  selection locally via `shared_preferences`.
- Settings screen now reads/writes that selection instead of a local,
  never-saved `Set`, and shows a banner (with a button straight to
  Settings > Accessibility) when the permission isn't granted yet.
- Focus Mode now passes the real selected package list to the blocker
  instead of a hardcoded empty list.

**You must do this manually, every time, per install** — Android does not
allow apps to request Accessibility access via a normal permission dialog:
1. Run the app, go to a focus session at least once (or just open Settings).
2. Settings screen shows a banner if the permission isn't granted — tap
   "Open Accessibility settings", find "FocusLock" in the list, and enable it.
3. Come back to the app. The banner clears automatically (checked whenever
   the app resumes).

**Limitations to know about:**
- This only works on Android. iOS does not allow third-party apps to block
  other apps at the OS level (Apple's own Screen Time / `FamilyControls` API
  is the only sanctioned mechanism, and it's considerably more restrictive).
- The block action is "send to home screen", not a hard lock — a
  determined user can still reopen the blocked app immediately after. This
  is the same approach most consumer app-blockers use; a stronger lock
  would need Device Owner / kiosk-mode provisioning, which is a much bigger
  commitment (typically MDM enrollment) and not appropriate for a
  general-audience app.
- Accessibility Services get extra scrutiny in Play Store review. Be ready
  to explain this exact use case (and only this use case) in the Play
  Console's permissions declaration form if you publish this.
