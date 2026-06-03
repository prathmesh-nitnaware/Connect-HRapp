# Connect HR & Employee Management System

## Project Overview

**Connect** is a comprehensive mobile application designed to simplify and automate HR operations and employee management tasks inside large organizations. This digital platform centralizes daily office-related activities, ensuring a seamless flow of communication between HR teams and employees.

### Key Features

* **Authentication System:** Secure JWT-based Login and Signup capabilities for employees.
* **Attendance Tracking:** Digital "Punch In" and "Punch Out" system for accurate timekeeping.
* **Leave Management:** Employees can effortlessly submit leave requests.
* **Employee Profiles:** Digital records mapping out employee designations, departments, and roles.
* **Role-Based Dashboards:** Distinct User Interfaces tailored exclusively for Employees and HR Admins.

## Technology Stack

The project is structured with a modern full-stack architecture:

### Frontend (Mobile App)
* **Framework:** Android Studio using **Kotlin** and **Jetpack Compose**.
* **Navigation:** Jetpack Navigation `androidx.navigation3`.
* **Networking:** Retrofit2 and OkHttp3 for asynchronous API communication.
* **Architecture:** Component-driven Material 3 Design featuring a polished Teal/Mint Green palette matching the original UX style guide.

### Backend (REST API)
* **Framework:** Python Flask and Flask-RESTful.
* **Authentication:** PyJWT for robust token generation and verification.
* **Security:** Werkzeug for strong, salted password hashing.

### Database
* **System:** MongoDB Atlas (NoSQL Cloud Database).
* **Driver:** PyMongo.
* **Collections:** `employees`, `attendance`, `leaves`.

## System Architecture

The frontend and backend are completely decoupled. The Android Application communicates with the Python backend entirely via RESTful API endpoints exchanging JSON data payloads. 

A central `SessionManager` securely retains the authentication JWT token locally within the app to attach to outbound network headers.

### API Endpoints Overview
* `POST /api/auth/signup` - Register a new employee.
* `POST /api/auth/login` - Authenticate and retrieve a JWT token.
* `GET /api/employee/profile` - Fetch authorized user profile details.
* `POST /api/attendance` - Punch In or Punch Out.
* `GET /api/attendance` - Retrieve a user's attendance history.
* `POST /api/leave` - Apply for a new leave request.
* `GET /api/leave` - Retrieve leave history status.


