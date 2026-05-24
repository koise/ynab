# 💰 YNAB — Modern Flutter Personal Finance App

[![Build Status](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Platform Compatibility](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-purple.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A premium, state-of-the-art personal finance tracker built with **Flutter** and **Cupertino Design**. Inspired by the SwiftUI architecture, this cross-platform solution features a fully reactive state model, dynamic color themes, local biometrics, interactive report analytics, and automated recurring billing processes.

---

## ✨ Features

- **📊 Modern Dashboard**: A high-fidelity dashboard displaying real-time balance calculations, monthly income-versus-expense cashflows, pending budget limit alerts, and a quick-action feed of your latest transactions.
- **🏷️ Smart Budgets**: Set category-specific monthly spending limits with elegant, color-coded progress bars (green → yellow → red) and over-budget highlighting.
- **💳 Unified Transaction Registry**: Live transaction ledger grouped chronologically by date headers with real-time fuzzy text searching, swipe-to-delete integrity protection, and type filters.
- **🔁 Recurring Payment Automations**: Auto-generate recurring transactions (daily, weekly, monthly, yearly) on their respective due dates with built-in notification hooks.
- **📈 Rich Visual Analytics**: Full-featured analytics using `fl_chart`, featuring Category Donut Charts, Net Balance Trends, and Income vs. Expense monthly bar charts.
- **🔒 High-Security Lock Gate**: Secure local access gate utilizing biometric auth (FaceID/TouchID) or a custom Cupertino 6-digit numeric PIN pad with built-in brute-force prevention and lock cooldowns.
- **📑 Data Exports**: Fast local compiles generating standard CSV ledgers or beautiful print-ready PDF reports with native system share sheet hooks.
- **🌓 Adaptive Brand Themes**: Beautiful, dynamic light and dark theme configurations that seamlessly switch based on the user's preference or system environment.

---

## 🛠️ Tech Stack & Architecture

- **UI Framework**: Cupertino (iOS Design Language) for premium look and feel.
- **State Management**: `Provider` + `ChangeNotifierProxyProvider` for decoupled dependency injection and reactive rebuilding.
- **Backend / Sync**: Google Firebase Core, Authentication, and Cloud Firestore.
- **Local Storage**: `flutter_secure_storage` (with native Keychain/Keystore encryption) for biometric/PIN data.
- **Analytics & Graphs**: `fl_chart` for highly customizable vector animations.
- **Notifications**: `flutter_local_notifications` for local scheduling.

---

## 🚀 Installation & Getting Started

### 📋 Prerequisites

Ensure you have the following installed on your developer machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0 or higher recommended)
- [Dart SDK](https://dart.dev/get/sdk)
- Xcode (for iOS builds - macOS required)
- Android Studio / Android SDK (for Android builds)

### ⚙️ Step-by-Step Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/koise/ynab.git
   cd ynab
   ```

2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Project Setup**:
   This project uses Firebase for authentications and data synchronization. Follow these steps to configure your own instance:
   
   - Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
   - Enable **Firebase Authentication** (Email/Password & Anonymous sign-in methods).
   - Enable **Cloud Firestore** in production or test mode.
   - Run the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup?platform=web) to configure platform-specific setups:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```
   - This will automatically generate a custom `lib/firebase_options.dart` containing your environment configurations.

4. **Add Local Keys / Android Setup**:
   - Ensure the Android `minSdkVersion` in `android/app/build.gradle` is set to `23` or higher (required by local biometric authentication).
   - Set up permissions for biometric logins:
     - **iOS**: Add the `NSFaceIDUsageDescription` key to `ios/Runner/Info.plist`.
     - **Android**: Ensure `USE_BIOMETRIC` permissions are defined in `AndroidManifest.xml`.

---

## 🏃 Running the Application

### 💻 Local Development Server
To run the app locally on a connected emulator, simulator, or browser, use:
```bash
flutter run
```

To run specifically on a web target (e.g., Chrome or Edge):
```bash
flutter run -d chrome
# or
flutter run -d edge
```

### 📦 Building Production Bundles

Compile production-optimized versions of your app using:

- **Android (APK)**:
  ```bash
  flutter build apk --release
  ```
- **Android (App Bundle for Play Store)**:
  ```bash
  flutter build appbundle --release
  ```
- **iOS (IPA Bundle)**:
  ```bash
  flutter build ipa --no-codesign
  ```
- **Web Build**:
  ```bash
  flutter build web --release
  ```

---

## 📂 Project Structure

```
lib/
├── components/          # Reusable UI widgets (cards, picker sheets, inputs)
│   ├── app_colors.dart             # Central theme system
│   ├── AppFAB.dart                 # Custom floating action button
│   ├── balance_card.dart           # Dashboard overall balance card
│   └── budget_progress_bar.dart    # Color-coded linear progress indicator
├── models/              # JSON-serializable Dart data models
│   └── models.dart                 # Enums and core class schemas
├── providers/           # Global provider wiring configurations
│   └── app_providers.dart          # Aggregated MultiProvider hierarchy
├── services/            # Infrastructure & native API bindings
│   ├── auth_service.dart           # Firebase authentication logic
│   ├── data_store.dart             # Live Firestore listeners & CRUD
│   ├── export_service.dart         # PDF/CSV compilation utilities
│   └── notification_service.dart   # Local schedule system
└── views/               # Screen widgets structured by functional domain
    ├── auth/                       # Login, registration, & PIN/Biometric lock
    ├── budgets/                    # Limit configurations and listings
    ├── dashboard/                  # Main landing interface
    ├── transactions/               # Ledgers, search, and detail sheets
    ├── reports/                    # Vector graph analytics
    └── settings/                   # Custom preferences and backup exports
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
