# Tiffin — Flutter Meal Subscription App

A cross-platform Flutter application for subscribing to daily tiffin (meal) plans, managing orders and deliveries, and handling user authentication and subscriptions via Firebase.

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

## Overview
Tiffin is built to let users browse meal plans, subscribe to recurring deliveries, place orders, track deliveries, and manage accounts. Authentication, orders, and subscriptions are backed by Firebase services; there are also Cloud Functions used for email OTP and helper tasks.

## Key Features
- User authentication (OTP/email) using Firebase Auth
- Browse meal plans and view details
- Subscribe to recurring tiffin plans
- Place and manage orders
- Delivery tracking UI
- Invoice and subscription history
- Localized strings and theme support
- Cloud Functions for OTP/email sending

## Tech Stack
- Flutter & Dart
- Firebase (Authentication, Firestore, Cloud Functions)
- Firebase Cloud Functions (Node.js) in `/functions`
- Platform targets: Android, iOS, Web, Windows, macOS, Linux

## Demo / Screenshots
Add screenshots under `assets/images/` and reference them here. Example:
- `assets/images/splash.png`
- `assets/images/meal_list.png`
- `assets/images/subscription.png`

## Getting Started

### Prerequisites
- Flutter (stable) installed — https://flutter.dev
- Dart SDK (bundled with Flutter)
- Firebase CLI (optional, for configuration/deploy)
- Node.js & npm (required for Firebase Functions)

### Clone
```bash
git clone <repo-url>
cd tiffin
