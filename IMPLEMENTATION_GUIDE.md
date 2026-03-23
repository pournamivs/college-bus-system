# Implementation Guide for College Bus System

## Complete Setup Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/pournamivs/college-bus-system.git
   cd college-bus-system
   ```
2. Install Flutter SDK:
   - Follow the installation guide for your OS from [Flutter Installation](https://flutter.dev/docs/get-started/install).
3. Get dependencies:
   ```bash
   flutter pub get
   ```

## Dashboard Implementations
- The dashboard comprises several screens:
  - Home Screen
  - Etinerary Screen
  - Feedback Screen

### Home Screen
- Displays current routes and bus status.

### Itinerary Screen
- Allows users to view and customize their travel plans.

### Feedback Screen
- Provides a platform for users to submit their feedback.

## Services
- The application uses several services, including:
  - Authentication Service
  - Location Tracking Service
  - Notification Service

## Firebase Configuration
1. Set up Firebase project:
   - Go to [Firebase Console](https://console.firebase.google.com/).
   - Create a new project and add an Android app.
2. Download the `google-services.json` and place it in `android/app/`.
3. Add the Firebase dependencies to your `pubspec.yaml` file:
   ```yaml
   dependencies:
     firebase_core: latest_version
     firebase_auth: latest_version
     cloud_firestore: latest_version
     ```

## Step-by-Step Guide to Run the Flutter Mobile App
1. Ensure you have a connected device or emulator.
2. Run the following command in the terminal:
   ```bash
   flutter run
   ```
3. Follow the instructions in the console to view the application.

---

### Notes
- Make sure to configure your Flutter environment properly before running the app.