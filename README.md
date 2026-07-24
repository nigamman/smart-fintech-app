# Fumet - Smart AI Fintech Ledger & Budget Companion

[![Flutter Version](https://img.shields.io/badge/Flutter-^3.10.8-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-Private-red.svg)](#)
[![Backend](https://img.shields.io/badge/Backend-Firebase-orange.svg)](https://firebase.google.com)
[![Local DB](https://img.shields.io/badge/Database-Hive-yellow.svg)](https://docs.hivedb.dev)

Fumet is a premium, feature-rich personal finance tracker and budget companion application built with Flutter. Designed with a gorgeous, dark-themed glassmorphic interface, Fumet leverages local AI heuristics, home screen widgets with background synchronization, and a privacy shield encryption engine to offer users a secure, private, and highly interactive financial ledger.

---

## 🚀 Key Features

### 🔐 1. Authentication & Onboarding
* **Multi-Provider Authentication:** Supports Firebase Auth for standard Email/Password login, Signup, and Password Recovery, alongside integrated **Google Sign-In**.
* **Profile Setup & Guard Rails:** Mandatory onboarding flow requiring users to input their monthly income and saving goals to compute health metrics from day one.

### 📊 2. Premium Interactive Dashboard
* **Dynamic Scorecards:** Displays net worth, cash balance, and real-time Safe-to-Spend limit.
* **Proactive Financial Nudges:** Evaluates local ledger state and provides AI-powered advisory alerts warning users of upcoming subscription renewals and budget limits.
* **Visual Spend Analysis:** Fully interactive charts (line graphs, bar charts, and pie charts) powered by `fl_chart`.

### 👥 3. Split Ledger (Bill Splitting)
* **Peer-to-Peer Splitting:** Split specific transaction amounts with friends by custom percentages.
* **Payment State Tracking:** Track pending and settled dues per friend, with options to mark individual split shares as paid.

### 🤖 4. AI Financial Counsel
* **Interactive AI Chat:** A conversational assistant page using local heuristic engines representing the Gemini model architecture.
* **Affordability Engine:** Evaluates user queries (e.g., *"Can I afford a ₹3,000 watch?"*) against safe-to-spend velocity, category budgets, and total balances to output contextual advice (*"Yes"*, *"No"*, or *"Yes-if"*).

### 🏷️ 5. Budget Planning & Goals
* **Category Limits:** Set monthly budget thresholds across multiple categories (e.g., Food, Shopping, Travel, Entertainment).
* **Savings Target Milestones:** Define targets (e.g., Emergency Fund), log savings progress, and visually track target milestones.

### 📅 6. Calendar View
* **Financial Calendar:** Dynamic monthly calendar layout displaying transaction logs and subscription renewal schedules to track monthly cash flow cycles.

### 🛡️ 7. Privacy Shield Encryption
* **AES-256-CBC Encryption:** Encrypts local transactions with a user-defined passphrase using PBKDF/SHA-256 key derivation.
* **Masked Metadata Sync:** Before syncing database models to the cloud, sensitive fields (`amount`, `category`, `note`, `type`) are encrypted into a secure payload while keeping non-identifiable routing fields public.

### 📲 8. Home Screen Widget Sync
* **Interactive Widgets:** Displays current cash balance and quick-add actions directly on the device's home screen using `home_widget`.
* **Deep Link Background Service:** Tap interactive action widgets on your home screen to trigger deep links (`fumet://add_expense`) that initialize Firebase and record quick transactions in background isolates.

### 📄 9. Statement & Data Export
* **Format Exports:** Export transaction histories directly to **CSV** sheets or premium branded **PDF** statements.
* **Native Share Integration:** Uses `share_plus` to dispatch generated files to target apps on Android and iOS.

---

## 🏛️ Architecture & Project Directory Structure

Fumet adheres to **Clean Architecture** principles structured by **Features** (Feature-First approach). This isolates presentation, domain, and data layers to maximize code testability and maintainability.

```text
lib/
├── app/                      # Application entry config
│   ├── app.dart              # Main MaterialApp & Theme Config
│   ├── app_router.dart       # GoRouter configuration & guards
│   ├── app_routes.dart       # Application Route constants
│   └── app_theme.dart        # Theme styles & dark-mode configurations
├── commons/                  # Shared UI widgets and resources
│   ├── models/               # Universal/Global UI models
│   ├── providers/            # Shared state providers
│   └── widgets/              # Reusable components (e.g. BouncyButton, CustomSnackBar)
├── core/                     # Infrastructure & Core Services
│   ├── constants/            # Core system constants
│   ├── enums/                # Universal Enums (e.g. TransactionCategory, TransactionType)
│   ├── errors/               # Failure & Exception classes
│   ├── extensions/           # Dart type extensions
│   ├── services/             # Background services
│   │   ├── encryption_helper.dart  # AES-256-CBC encryption engine
│   │   ├── export_service.dart      # PDF and CSV generator
│   │   ├── firebase_services.dart  # Firebase helper routines
│   │   ├── gemini_service.dart     # AI heuristic & nudge logic
│   │   ├── hive_services.dart      # Local key-value database
│   │   └── home_widget_service.dart# Interactive home screen widgets
│   ├── theme/                # Aesthetic parameters (AppColors, AppSpacing, AppTextStyles)
│   ├── utils/                # General util functions
│   └── types.dart            # Standard type definitions
└── features/                 # Modular application features
    ├── analytics/            # Spend charts, insights, and AI chat screens
    ├── auth/                 # Authentication state, login, signup, splash
    ├── budget/               # Budgets category constraints, planning view
    ├── calendar/             # Monthly financial schedule view
    ├── dashboard/            # Core navigation shell, dashboards & alerts
    ├── onboarding/           # Welcome slides & initial user metrics setup
    ├── profile/              # User summary profiles
    ├── savings_goal/         # Target saving tracking & milestones
    ├── settings/             # System settings & profile updates
    ├── subscription/         # Subscription limits, upcoming bills
    └── transaction/          # Transaction CRUD, split ledger screens, models
```

### Clean Architecture Layer Segregation

Each folder under `features/[feature_name]` is split into three layers:
1. **Domain Layer:** Contains core business entities (`Entity`), repository contracts/interfaces, and use cases. This layer is entirely independent of external frameworks.
2. **Data Layer:** Implements repositories, data models (`Model` extending domain entities) with JSON mapping helpers, and remote/local data source adapters.
3. **Presentation Layer:** Manages states via Riverpod (`StateProvider`, `NotifierProvider`, `FutureProvider`) and renders pages using Flutter components.

---

## 🛠️ Technology Stack & Dependencies

| Dependency | Purpose |
| :--- | :--- |
| **flutter_riverpod** | Unified and type-safe state management |
| **go_router** | Declarative router supporting deep linking and redirect guards |
| **firebase_core** / **firebase_auth** | Backend configuration and secure user registration |
| **cloud_firestore** | Cloud database sync for online data replication |
| **hive** / **hive_flutter** | Offline-first local database cache |
| **fl_chart** | Modern interactive data visualizations |
| **home_widget** | Integration for home screen widgets (native interactive widgets) |
| **encrypt** / **crypto** | Passphrase-based AES-256-CBC local encryption |
| **pdf** / **csv** | Statement compilation and data table formatting |
| **share_plus** | Native sharing sheets for exporting statements |
| **google_sign_in** | Single Sign-On (SSO) login capabilities |
| **google_fonts** | Outfit, Inter and custom typography |

---

## ⚙️ Getting Started & Local Setup

### Prerequisites
* Flutter SDK (`>= 3.10.8` recommended)
* Android Studio / Xcode configured for emulator testing
* A Firebase Project configured with Firestore and Email/Password & Google Sign-In providers enabled.

### 1. Installation
Clone the repository and pull the Dart dependencies:
```bash
git clone <repository-url>
cd fintech_app
flutter pub get
```

### 2. Configure Firebase
Download your project settings from Firebase and register the config files:
* Place `google-services.json` in `android/app/`
* Place `GoogleService-Info.plist` in `ios/Runner/`
* Alternatively, run the Firebase CLI configurations to generate the options:
```bash
flutterfire configure --project=smart-fintech-app
```

### 3. Build & Run
To run the app in debug mode on a connected device or emulator:
```bash
flutter run
```

### 4. Code Generation (Launcher Icons)
If you update assets or launcher icons, regenerate them via `flutter_launcher_icons`:
```bash
flutter pub run flutter_launcher_icons
```

---

## 🧪 Testing Suite

Fumet includes structured test suites located in the `/test` directory:

1. **`gemini_service_test.dart`**: Validates AI local heuristic rules, proactive nudges, budget boundary warnings, and conversational affordability responses.
2. **`privacy_shield_test.dart`**: Tests the `EncryptionHelper` AES algorithms and ensures `TransactionModel` encrypts/decrypts fields accurately.
3. **`split_test.dart`**: Tests split ledger serializations, friend payment state updates, and out-of-pocket calculation logic.

To execute the test suite, run:
```bash
flutter test
```
