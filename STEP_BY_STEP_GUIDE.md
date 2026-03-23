# STEP BY STEP GUIDE: Running TrackMyBus Flutter App in VS Code

This guide provides comprehensive instructions on how to run the TrackMyBus Flutter app in Visual Studio Code. Follow the steps below to get started.

## Step 1: Install Flutter SDK
1. Download the Flutter SDK from the official website: [Flutter Installation](https://flutter.dev/docs/get-started/install)
2. Extract the downloaded zip file and add the `flutter/bin` directory to your system's PATH environment variable.

## Step 2: Install Android Studio
1. Download Android Studio from the official website: [Android Studio Download](https://developer.android.com/studio)
2. Follow the installation instructions. Make sure to include the Android SDK.

## Step 3: Set Up an Emulator
1. Open Android Studio and navigate to `Tools > AVD Manager`.
2. Create a new Virtual Device by following the prompts and selecting a device definition and system image.

## Step 4: Clone the Repository
1. Open a terminal and navigate to the directory where you want to clone the repository.
2. Run the following command:
   ```bash
   git clone https://github.com/pournamivs/college-bus-system.git
   ```

## Step 5: Open the Project in VS Code
1. Launch Visual Studio Code.
2. Select `File > Open Folder` and choose the `college-bus-system` folder.

## Step 6: Install Flutter and Dart Extensions
1. In VS Code, navigate to the Extensions view by clicking on the Extensions icon or pressing `Ctrl+Shift+X`.
2. Search for and install the "Flutter" and "Dart" extensions.

## Step 7: Associate Project with Flutter SDK
1. Open the command palette with `Ctrl+Shift+P`.
2. Type and select `Flutter: Select Device` to choose an emulator.

## Step 8: Run the Application
1. Open the terminal in VS Code (`Ctrl + ``).
2. Navigate to the project directory (if not already there):
   ```bash
   cd college-bus-system
   ```
3. Run the app with:
   ```bash
   flutter run
   ```

## Step 9: Troubleshooting Common Issues
- If the app doesn't launch, ensure that:
  - The Flutter SDK path is configured correctly.
  - You have selected an active device (emulator).
  - There are no dependency issues; run `flutter pub get` to fetch dependencies.

## Step 10: Useful Keyboard Shortcuts
- **Run Flutter Application:** `F5`
- **Open Command Palette:** `Ctrl+Shift+P`
- **Show Debugger:** `Ctrl+Shift+D`

Follow these steps carefully to ensure a smooth setup and execution of the TrackMyBus Flutter app in VS Code.