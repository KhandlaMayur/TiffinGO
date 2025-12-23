# 🍱 TiffinGO

TiffinGO is a mobile application that helps users subscribe to daily tiffin services, manage meal plans, track remaining orders, and handle payments easily. The app digitalizes the traditional tiffin system using modern mobile and cloud technologies.

---

## Table of Contents
- [Overview](#overview)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Demo / Screenshots](#demo--screenshots)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Available Scripts](#available-scripts)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Overview
Tiffin is built to let users browse meal plans, subscribe to recurring deliveries, place orders, track deliveries, and manage accounts. Authentication, orders, and subscriptions are backed by Firebase services; there are also Cloud Functions used for email OTP and helper tasks.

---

## Key Features
- User authentication (OTP/email) using Firebase Auth
- Browse meal plans and view details
- Subscribe to recurring tiffin plans
- Place and manage orders
- Delivery tracking UI
- Invoice and subscription history
- Localized strings and theme support
- Cloud Functions for OTP/email sending

---

## Tech Stack
- Flutter & Dart
- Firebase (Authentication, Firestore, Cloud Functions)
- Firebase Cloud Functions (Node.js) in `/functions`
- Platform targets: Android, iOS, Web, Windows, macOS, Linux

---

## Getting Started

### Prerequisites
- Flutter (stable) installed — https://flutter.dev
- Dart SDK (bundled with Flutter)
- Firebase CLI (optional, for configuration/deploy)
- Node.js & npm (required for Firebase Functions)
- 
---
### Clone
```bash
git clone <repo-url>
cd tiffin
git clone https://github.com/KhandlaMayur/TiffinGO.git
cd TiffinGO
flutter pub get
flutter run
