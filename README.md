# Connect HR & Employee Management System

![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Android%20%7C%20iOS%20%7C%20Web-02569B?style=flat&logo=flutter)
![Backend](https://img.shields.io/badge/Backend-Full--Stack%20Dart%20Shelf-0175C2?style=flat&logo=dart)
![Database](https://img.shields.io/badge/Database-MongoDB%20%2F%20In--Memory-47A248?style=flat&logo=mongodb)

**Connect** is a comprehensive, modern full-stack application designed to simplify and automate HR operations and employee management tasks inside organizations. The repository is structured as a unified Flutter and Dart full-stack application with an asynchronous Dart Shelf REST API backend.

---

## ✨ Key Features

### 🔐 Advanced Authentication & Security
* **JWT-Based Security:** Secure Login and Signup using signed JSON Web Tokens (`dart_jsonwebtoken`).
* **Role-Based Access Control:** Strict segregation between regular Employees and HR Administrators.
* **Data Privacy:** HR users and Employee users are stored in separate collections (`hr_users` and `employees`), ensuring complete data segregation and that HR staff do not appear in employee directories.

### 👥 Employee Portal
* **Digital Attendance Tracking:** Seamlessly "Punch In" and "Punch Out" directly from the dashboard.
* **Leave Management:** Submit sick leaves, vacation days, and remote work requests with calendar picking.
* **Interactive Dashboard:** Quick Action cards providing one-tap access to daily essentials and recent activity logs.

### ⚙️ HR Administrator Portal
* **Real-time Analytics:** Dynamically displays live organizational metrics (Total Employees, Present Today, Pending Leaves).
* **Employee Directory Management:** Hire new employees, update departments, and offboard personnel directly through modern Contact Cards.
* **Attendance Oversight:** Review company-wide punch-in and punch-out records.
* **Leave Approvals:** A dedicated queue for HR to accept or reject employee leave requests with status badges.

### 🎨 Premium User Interface
* **Material 3 Design:** Built in Flutter using Material Design 3 guidelines.
* **Dynamic Theming:** Features an Indigo & Teal color palette that adapts to both **Dark Mode** and **Light Mode**.
* **Clean Card Layouts:** Spacious, elevated card UI with custom animations and typography.

---

## 🛠 Project Structure

```
Connect-HRapp/
├── lib/                             # Flutter Cross-Platform Frontend
│   ├── main.dart                    # App Entry & MultiProvider setup
│   ├── core/                        # Theme, colors, routes, network client & session
│   │   ├── constants/               # API constants & App colors
│   │   ├── network/                 # ApiService & ApiException
│   │   ├── routes/                  # AppRoutes
│   │   ├── services/                # SessionService (SharedPreferences)
│   │   └── theme/                   # Material 3 lightTheme & darkTheme
│   ├── models/                      # Typed data models (Auth, Employee, Leaves, Attendance)
│   ├── providers/                   # State management (AuthProvider, EmployeeProvider, HRProvider, ThemeProvider)
│   ├── screens/                     # Landing, Auth, Employee & HR Dashboard screens
│   └── widgets/                     # Reusable Material 3 UI widgets & dialogs
├── server/                          # Full-Stack Dart REST API Backend
│   ├── .env                         # Environment configuration
│   ├── .env.example                 # Environment configuration template
│   ├── pubspec.yaml                 # Shelf, JWT, CORS, Crypto, Mongo_dart dependencies
│   ├── bin/
│   │   └── server.dart              # Shelf router, CORS pipeline & server entry point
│   ├── lib/
│   │   ├── config/                  # ServerConfig
│   │   ├── controllers/             # AuthController, EmployeeController, HRController
│   │   ├── db/                      # DatabaseService (MongoDB Atlas + In-Memory store)
│   │   ├── middleware/              # AuthMiddleware (JWT verification)
│   │   └── utils/                   # PasswordHasher
│   └── test/
│       └── server_test.dart         # Server integration tests
├── test/
│   └── widget_test.dart             # Flutter smoke & widget tests
├── pubspec.yaml                     # Flutter project dependencies
└── analysis_options.yaml            # Static analysis configuration
```

---

## 🚀 Getting Started (Local Development)

### 1. Start the Dart Backend Server
1. Navigate to the `server` directory:
   ```bash
   cd server
   ```
2. Install server dependencies:
   ```bash
   dart pub get
   ```
3. Run the server:
   ```bash
   dart run bin/server.dart
   ```
   > **Note:** The server includes a `.env` file and automatically boots with a built-in mock/in-memory store with pre-seeded test accounts if no external MongoDB Atlas URI is set.
   * **HR Admin:** `hr@connect.com` / `admin123`
   * **Employee:** `john@connect.com` / `password123`

### 2. Launch the Flutter App
1. From the project root (`Connect-HRapp`):
   ```bash
   flutter pub get
   flutter run
   ```
   * *Web:* `flutter run -d chrome`
   * *Desktop:* `flutter run -d windows`
   * *Mobile:* Run on your connected Android emulator or physical device.
2. *Tip:* You can change the API Base URL dynamically using the **Server Settings** icon in the AppBar.
