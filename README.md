# دليل المتفوقين — Daleel Al-Motafawqeen

Flutter frontend for the 5 screens you requested. This is **UI only** —
all data comes from `lib/data/mock_data.dart` — no backend/auth is wired
up yet. See "Next steps" below for that.

## What's included
- `lib/theme/app_theme.dart` — colors, type scale, component theme (royal
  blue `#1A56DB` / sky blue `#38BDF8`, Cairo font, RTL-ready)
- `lib/widgets/common_widgets.dart` — shared pieces (logo, buttons, stat
  cards, badges, the swoosh header)
- `lib/screens/` — the 5 screens, one file each
- `lib/screens/dev_menu_screen.dart` — a temporary picker screen so you
  can jump to any of the 5 screens without a real login. Delete once
  auth is real.
- `assets/logo.png` — your logo, cropped from the screenshot you sent

## Setup from scratch in VS Code

1. **Install Flutter SDK** (skip if already installed):
   Download from https://docs.flutter.dev/get-started/install and follow
   the steps for your OS. Confirm it worked:
   ```
   flutter doctor
   ```
   Resolve anything `flutter doctor` flags as missing (Android SDK /
   Xcode / VS Code plugin) before continuing.

2. **Install VS Code extensions**: open VS Code → Extensions →
   install **Flutter** (this pulls in the Dart extension automatically).

3. **Get this project into VS Code**:
   - Unzip the project you downloaded from this chat.
   - In VS Code: `File → Open Folder…` → select the
     `daleel_al_motafawqeen` folder.

4. **Install dependencies** — open a terminal in VS Code
   (`` Ctrl+` ``) and run:
   ```
   flutter pub get
   ```

5. **Run it**:
   - Plug in a phone (with USB debugging on) or start an emulator/simulator
     from VS Code's device picker (bottom-right corner).
   - Press `F5`, or run:
     ```
     flutter run
     ```
   - The app opens on the dev screen picker — tap any screen to preview it.

6. **Hot reload while you work**: save any `.dart` file and the running
   app updates instantly (or press `r` in the terminal).

## Next steps (not built yet — flag these before you scale this up)
- **Auth + database**: Firebase (Auth + Firestore) is the fastest path
  for a solo-teacher app like this — free tier easily covers one
  teacher's student count, and Firestore's structure maps naturally
  onto teacher → groups → students.
- **File storage** for the homework PDFs: Firebase Storage.
- **Push notifications** for "إشعار فوري": Firebase Cloud Messaging.
- **Decide the monthly-reset rule** for "متبقي حصص" before modeling the
  payments collection (see my notes in chat).
- Replace `lib/data/mock_data.dart` with real API/Firestore calls once
  the backend exists — the screens are already built to take that data
  shape, so this should be a drop-in swap, not a rewrite.
