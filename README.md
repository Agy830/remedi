# Remedi 

Remedi is a modern, Flutter-based medication adherence application designed to help patients track their prescriptions and caregivers to monitor adherence.

## Features

*   **Medication Scheduling**: Easily add medications with frequency, dosage, and specific times.
*   **Smart Notifications**: Reliable local notifications that work offline.
    *   **Custom Sounds**: Choose between Loud, Soft, or Long alarm sounds.
    *   **Persistent Alarms**: Option to keep the alarm ringing until the user acknowledges it.
    *   **Actionable**: Mark as "Taken" directly from the notification.
*   **Adherence Tracking**:
    *   **Calendar View**: Visual history of Taken vs. Missed medications.
    *   **Missed Dose Detection**: Automatically flags doses not taken within a specific timeframe.
*   **Patient Profile**:
    *   **Dark Mode**: Fully supported dark theme for low-light comfortable usage.
    *   **Caregiver Linking**: Securely link with caregivers using a unique Patient ID for remote adherence monitoring.
*   **Cloud Sync ☁️**:
    *   **Real-time Synchronization**: Medications are automatically pushed to Supabase.
    *   **Multi-Role Access**: Caregivers can view medication schedules and status in real-time.


## Getting Started 

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
*   Android Studio / VS Code
*   Android Device or Emulator (API 26+)

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Agy830/remedi.git
    cd remedi
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the app**:
    ```bash
    flutter run
    ```

## Logo & Splash Screen 🎨

To customize the app's launcher icon and loading (splash) screen, follow these steps:

1. **Prepare your Image**:
   * For the best results, use a **1024x1024** PNG image.
   * Ensure your main logo mark is perfectly centered within the image canvas.
   * To avoid a "boxy" look on the background, the image should ideally have a **transparent background**.
   * Save the image and copy it to: `assets/icons/remedi_icon.png`.

2. **Update the App Icon**:
   * Open the terminal and run the Flutter Launcher Icons package to generate icons for all platforms:
     ```bash
     dart run flutter_launcher_icons
     ```

3. **Update the Splash Screen**:
   * Look for the `flutter_native_splash:` section at the bottom of `pubspec.yaml` to change the background color (`color: "#ffffff"`) to match your app's theme.
   * Then, run the Splash Screen generator:
     ```bash
     dart run flutter_native_splash:create
     ```

4. **Rebuild**:
   * Because these are native Android/iOS changes, you *must* completely stop the app and run `flutter run` again for the new images to compile into the app bundle.

## Onboarding Screen 🛣️
If you want to edit or test the Onboarding screens without reinstalling the app:
* Open `lib/main.dart`
* Change `final showOnboarding = !prefs.containsKey('onboarding_complete');` to `final showOnboarding = true;` (temporarily).
* Edit the slides in `lib/screens/onboarding_screen.dart`.

## Project Structure 📂

### **Core** (`lib/`)
*   **`main.dart`**: The entry point. Initializes services (`NotificationService`, `SharedPreferences`), sets up Riverpod `ProviderScope`, and decides whether to show the Onboarding screen or the Main App.

### **Core Services** (`lib/services/`)
*   **`notification_service.dart`**: The engine for local notifications. Handles:
    *   Requesting permissions (Android/iOS).
    *   Scheduling exact alarms & zoned schedules.
    *   Managing Notification Channels (Sounds/Vibration).
    *   Handling background actions (like "Mark as Taken" from the lock screen).

### **Database** (`lib/database/`)
*   **`db_helper.dart`**: Manages the SQLite database using `sqflite`.
    *   `medications` table: Stores prescription details (name, dosage, time, schedule).
    *   `medication_logs` table: Stores history of Taken/Missed doses for calendar tracking.

### **Data Models** (`lib/models/`)
*   **`medication.dart`**: Data model class representing a medication entity.

### **Data Layer** (`lib/repositories/`)
*   **`medication_repository.dart`**: Abstract interface and SQLite implementation (`SqliteMedicationRepository`) that decouples the UI from the direct Database calls. This allows for easier testing and future backend swaps.

### **State Management** (`lib/providers/`)
*   **`providers.dart`**: The core Dependency Injection file using Riverpod. It defines:
    *   `activeMedicationsProvider`: A stream of medications that updates automatically when the database changes.
    *   `medicationRepositoryProvider`: Provides access to the underlying data source.
    *   `MedicationController`: Handles business logic like adding medications and marking them as taken.
*   **`theme_provider.dart`**: Manages the application's Theme Mode (System/Light/Dark) and persists the user's preference.

### **Patient Screens** (`lib/screens/patient/`)
*   **`patient_shell.dart`**: The main scaffold for patients, containing the contents and the Bottom Navigation Bar.
*   **`patient_home_screen.dart`**: The Dashboard. Shows today's medications, allows marking them as taken, and tracks missed doses.
*   **`add_medication_screen.dart`**: A form to add new prescriptions. Handles validation and schedules the initial notifications.
*   **`patient_calendar_screen.dart`**: Shows a monthly calendar view of adherence history.
*   **`patient_profile_screen.dart`**: Settings page. Contains Dark Mode toggle, Notification settings, and Profile info.

### **Caregiver Screens** (`lib/screens/caregiver/`)
*   **`caregiver_shell.dart`**: Main scaffold for the Caregiver view.
*   **`dashboard/caregiver_dashboard_screen.dart`**: Shows adherence statistics and a read-only list of the patient's medications.
*   **`settings/caregiver_settings_screen.dart`**: Caregiver-specific settings.

### **Utilities** (`lib/utils/`)
*   **`time_formatter.dart`**: A helper class for date and time manipulations.
    *   Converts database 24-hour strings (e.g., "14:30") to user-friendly 12-hour format ("2:30 PM").
    *   Formats DateTimes into readable strings (e.g., "Jan 15, 2024").

### **Reusable Widgets** (`lib/widgets/`)
*   **`medication_card.dart`**: A smart UI component that displays a single medication.
    *   Handles the visual logic for "Taken" (strikethrough/green) vs "Pending" (teal) states.
    *   Includes swipe-to-delete contextual actions (for Patients) or read-only view (for Caregivers).

---

### **Android Configuration** (`android/`)
*   **`android/app/src/main/AndroidManifest.xml`**:
    *   Defines permissions for `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, and `USE_FULL_SCREEN_INTENT`.
    *   Registers the `FlutterLocalNotificationsPlugin` receiver for background updates.

### **Assets** (`assets/`)
*   **`assets/sounds/`**: Custom notification sounds.
    *   `alarm_loud.mp3`
    *   `alarm_soft.mp3`
    *   `alarm_long.mp3`
    *   `notification.mp3` (Default)
*   **`android/app/src/main/res/drawable/`**: App icons and notification icons (`ic_launcher.png`, etc.).

## Localization 

Currently supported:
*   English (en)

*Planned Support:*
*   Hausa (ha)
*   Igbo (ig)
*   Yoruba (yo)
*   Arabic (ar)
*   French (fr)

## Contributing 

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request
