# Running the TrackMyBus Flutter App in VS Code

This guide provides comprehensive instructions on how to run the TrackMyBus Flutter app in Visual Studio Code.

## Step 1: Open the Project
1. Launch Visual Studio Code.
2. Click on `File` > `Open Folder...`.
3. Navigate to the `TrackMyBus` project folder and select it.
4. Click `Open` to load the project.

## Step 2: Get Dependencies
1. Open the terminal in Visual Studio Code by selecting `View` > `Terminal`.
2. Ensure you are in the project directory. You can check this by running:
   ```bash
   pwd  # On macOS or Linux  
   cd  # On Windows
   ```
3. Run the following command to get the dependencies:
   ```bash
   flutter pub get
   ```

## Step 3: Add Firebase Files
1. Download the `google-services.json` file for Android from Firebase Console.
2. Place `google-services.json` in the `android/app/` directory.
3. Download the `GoogleService-Info.plist` file for iOS from Firebase Console.
4. Place `GoogleService-Info.plist` in the `ios/Runner/` directory.
5. Make sure to follow the Firebase project setup documentation to configure any additional settings required for your app.

## Step 4: Run the App
1. Connect a device or start an emulator.
2. In the terminal, run:
   ```bash
   flutter run
   ```
3. The app should launch in the selected device/emulator.

## Step 5: Troubleshooting
- **If you encounter issues:**
  - Ensure your Flutter SDK is up to date by running:
    ```bash
    flutter upgrade
    ```
  - Check if all the required dependencies are added correctly in `pubspec.yaml`.
  - Review your Firebase configuration.

- **Common Error Messages:**
  - If you see errors related to missing files, double-check that `google-services.json` and `GoogleService-Info.plist` are correctly placed.

## Step 6: Testing the Dashboards
1. To test the dashboards, ensure all backend services are running.
2. In the terminal, navigate to the dashboard directory:
   ```bash
   cd path_to_dashboard_directory
   ```
3. Run the dashboard by executing:
   ```bash
   flutter run
   ```
4. Verify if the dashboards are displaying data correctly.

## Conclusion
Following these steps should successfully set up and run the TrackMyBus Flutter app in Visual Studio Code. If you face any issues, refer to the Flutter documentation or Firebase setup guide for further assistance.