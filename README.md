# Connect HR & Employee Management System

![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat&logo=android)
![Backend](https://img.shields.io/badge/Backend-Python%20Flask-3776AB?style=flat&logo=python)
![Database](https://img.shields.io/badge/Database-MongoDB-47A248?style=flat&logo=mongodb)

**Connect** is a comprehensive, modern mobile application designed to simplify and automate HR operations and employee management tasks inside large organizations. This digital platform centralizes daily office-related activities, ensuring a seamless flow of communication between HR teams and employees, featuring a robust decoupled frontend-backend architecture and a premium user interface.

---

## ✨ Key Features

### 🔐 Advanced Authentication & Security
* **JWT-Based Security:** Secure Login and Signup capabilities using JSON Web Tokens.
* **Role-Based Access Control:** Strict segregation between regular Employees and HR Administrators.
* **Data Privacy:** HR users and Employee users are stored in entirely separate database collections (`hr_users` and `employees`), ensuring complete data segregation and that HR staff do not appear in employee directories.

### 👥 Employee Portal
* **Digital Attendance Tracking:** Seamlessly "Punch In" and "Punch Out" directly from the mobile app dashboard.
* **Leave Management:** Employees can effortlessly submit sick leaves, vacation days, and remote work requests.
* **Interactive Dashboard:** Modern Quick Action grid providing one-tap access to daily necessities.

### ⚙️ HR Administrator Portal
* **Real-time Analytics:** The HR Dashboard dynamically displays live organizational statistics such as Total Employees, Present Today, and Pending Leaves.
* **Employee Directory Management:** HR can hire new employees, update departments, and offboard personnel directly through modern "Contact Cards."
* **Attendance Oversight:** Review company-wide daily punch-in and punch-out records.
* **Leave Approvals:** A dedicated queue for HR to accept or reject employee leave requests with clear status badging.

### 🎨 Premium User Interface
* **Material 3 Design:** Built entirely in Jetpack Compose utilizing modern Material Design 3 guidelines.
* **Dynamic Theming:** Features a stunning Indigo & Teal color palette that perfectly adapts to both **Dark Mode** and **Light Mode** based on system settings.
* **Floating Elevated Layouts:** Clean, spacious, and elegant card-based UI that removes clutter and focuses on typography and whitespace.

---

## 🛠 Technology Stack

The project is structured with a modern full-stack decoupled architecture:

### Frontend (Android Mobile App)
* **Framework:** Android Studio, native Android.
* **Language:** Kotlin
* **UI Toolkit:** Jetpack Compose (Declarative UI)
* **Navigation:** Jetpack Navigation (`androidx.navigation3`)
* **Networking:** Retrofit2 and OkHttp3 for asynchronous API communication.
* **Coroutines:** Kotlin Coroutines for safe, thread-managed background tasks.

### Backend (REST API)
* **Framework:** Python Flask and Flask-RESTful for rapid API development.
* **Authentication:** PyJWT for robust token generation, verification, and decoding.
* **Security:** Werkzeug for strong, salted password hashing (`generate_password_hash`, `check_password_hash`).

### Database
* **System:** MongoDB Atlas (NoSQL Cloud Database).
* **Driver:** PyMongo.
* **Collections:** `employees`, `hr_users`, `attendance`, `leaves`.

---

## 🚀 System Architecture & API

The frontend and backend are completely decoupled. The Android Application communicates with the Python backend entirely via RESTful API endpoints exchanging JSON data payloads. 

A central singleton `SessionManager` securely retains the authentication JWT token locally within the app to attach to outbound network headers (`Bearer <token>`).

### Employee Endpoints
* `POST /api/auth/signup` - Register a new employee.
* `POST /api/auth/login` - Authenticate against `employees` and `hr_users`.
* `GET /api/employee/profile` - Fetch authorized user profile details.
* `POST /api/attendance` - Punch In / Punch Out.
* `GET /api/attendance` - Retrieve user's personal attendance history.
* `POST /api/leave` - Apply for a new leave request.
* `GET /api/leave` - Retrieve personal leave history.

### HR Endpoints (Requires `@hr_required` JWT)
* `GET /api/hr/analytics` - Fetch live company stats (Total employees, pending leaves, today's attendance).
* `GET /api/hr/employees` - List all company employees.
* `POST /api/hr/employees` - Register a new employee (Hire).
* `PUT /api/hr/employees/<id>` - Update employee details (e.g., Change Department).
* `DELETE /api/hr/employees/<id>` - Delete an employee (Fire/Offboard).
* `GET /api/hr/attendance` - View company-wide attendance records.
* `GET /api/hr/leaves` - View company-wide leave requests.
* `PUT /api/hr/leaves/<id>` - Approve or Reject a specific leave request.

---

## 💻 Getting Started (Local Development)

### 1. Backend Setup
1. Navigate to the `backend` directory: `cd backend`
2. Create a virtual environment: `python -m venv venv`
3. Activate the virtual environment:
   * Windows: `venv\Scripts\activate`
   * Mac/Linux: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt` (Ensure Flask, PyMongo, PyJWT, Werkzeug, python-dotenv, flask-restful are installed).
5. Create a `.env` file in the `backend` directory with your MongoDB Atlas URI:
   ```env
   MONGO_URI=mongodb+srv://<user>:<pass>@cluster.mongodb.net/?retryWrites=true&w=majority
   ```
6. Run the server: `python app.py`

### 2. Frontend Setup
1. Open Android Studio and open the `android-app` folder.
2. In `ApiService.kt` or `RetrofitClient.kt`, ensure the `BASE_URL` points to your backend server's IP address (e.g., `http://10.0.2.2:5000/api/` for Android Emulator, or your machine's local IPv4 address if using a physical device).
3. Sync Gradle.
4. Click **Run** (`Shift + F10`) to build and deploy to your emulator or physical Android device.
