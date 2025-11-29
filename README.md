# Lead Caller App

A robust Flutter-based lead management and dialing application designed for calling agents. This app integrates seamlessly with Google Sheets via Google Apps Script for a serverless backend, and uses Firebase Hosting for deployment.

## 📋 Overview

The **Lead Caller App** streamlines the process of calling leads. Agents can log in using OTP, fetch leads assigned to their state, initiate calls directly from the app, and submit call dispositions (outcomes) which are instantly recorded in a Google Sheet.

## 🏗️ Architecture

- **Frontend**: Flutter (Mobile & Web)
- **Backend**: Google Apps Script (GAS)
- **Database**: Google Sheets (Leads & Authorized Users)
- **Authentication**: OTP via SMSCountry API + Phone Number Validation against Google Sheet
- **Hosting**: Firebase Hosting

## ✨ Key Features

- **Secure Login**: OTP-based authentication with phone number validation.
- **Lead Management**:
    - **Fetch Leads**: Automatically fetches the next available lead for the agent's state.
    - **Search**: Ability to search for specific leads by phone number.
- **Smart Dialing**: One-tap calling using the device's native dialer.
- **Disposition Tracking**:
    - Record call outcomes (e.g., "Answered", "No Answer").
    - Add notes/comments.
    - Schedule follow-ups with a date picker.
- **Idle Timer**: Auto-logout after 30 minutes of inactivity to ensure security.
- **Dual Environment**: Separate setups for Production and Development.

---

## 🎨 UI Redesign (Development Branch)

The `main` branch features a completely modernized UI designed for a premium user experience.

### Login Screen
- **Visuals**: Vibrant Orange/Deep Orange gradient background.
- **Layout**: Clean card-based form with rounded inputs and modern typography.
- **Feedback**: Clear validation messages and loading states.

### Instruction Screen
- **Dashboard**: A colorful 2x2 grid of cards displaying quick instructions.
- **Header**: Personalized greeting with user avatar.

### Lead Caller Screen
- **Lead Card**: Distinct card displaying Lead Name and Phone with a prominent "CALL" button.
- **Disposition Form**:
    - Intuitive dropdowns and text fields.
    - **Conditional Logic**: Follow-up date picker appears only when "Yes" is selected.
- **History**: Collapsible "Previous History" section to view past interactions.

---

## 🛠️ Dual Deployment Setup

We maintain two distinct environments to ensure stability while innovating.

| Feature | Production (`production`) | Development (`main`) |
|---------|---------------------------|----------------------|
| **URL** | [dialer-ip.web.app](https://dialer-ip.web.app) | [dialer-ip-dev.web.app](https://dialer-ip-dev.web.app) |
| **UI** | Original Design | Modern Redesign |
| **Entry Point** | `lib/main_prod.dart` | `lib/main_dev.dart` |
| **Script** | `scripts/production/Code.gs` | `scripts/development/Code.gs` |
| **Firebase Project** | `dialer-ip` | `dialer-ip-dev` |

### Google Apps Scripts
The backend logic is version-controlled in this repository:
- **Production**: `scripts/production/Code.gs`
- **Development**: `scripts/development/Code.gs`

> **Note**: Any changes to these scripts must be manually deployed to the respective Google Apps Script projects.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x)
- Firebase CLI

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/rsagrawal/Dialer-IP.git
    cd Dialer-IP
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the App**:

    - **Development (New UI)**:
        ```bash
        flutter run -t lib/main_dev.dart
        ```

    - **Production (Original UI)**:
        ```bash
        flutter run -t lib/main_prod.dart
        ```

---

## 📦 Deployment

### Deploy to Production
```bash
git checkout production
firebase use dialer-ip
flutter build web -t lib/main_prod.dart
firebase deploy --only hosting
```

### Deploy to Development
```bash
git checkout main
firebase use dialer-ip-dev
flutter build web -t lib/main_dev.dart
firebase deploy --only hosting
```

---

## 📂 Project Structure

```
lib/
├── main_dev.dart       # Entry point for Development (New UI)
├── main_prod.dart      # Entry point for Production (Original UI)
└── ...
scripts/
├── development/
│   └── Code.gs         # Google Apps Script for Dev
└── production/
    └── Code.gs         # Google Apps Script for Prod
```

## 📝 License
Proprietary software for internal use.
