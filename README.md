# Connect HR Enterprise Workplace Platform

![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-02569B?style=flat&logo=flutter)
![Backend](https://img.shields.io/badge/Backend-Dart%20Shelf%20REST%20Engine-0175C2?style=flat&logo=dart)
![Database](https://img.shields.io/badge/Database-MongoDB%20Atlas%20%2F%20In--Memory-47A248?style=flat&logo=mongodb)
![Security](https://img.shields.io/badge/Security-JWT%20%2B%20PBKDF2%2FSha256-blueviolet?style=flat&logo=jsonwebtokens)
![License](https://img.shields.io/badge/License-Proprietary%20%2F%20Enterprise-orange?style=flat)

**Connect HR** is an enterprise-grade, full-stack Human Resource Management & Employee Experience Platform. Designed from the ground up to unify organizational workflows, workforce governance, payroll automation, and real-time support into a cohesive, high-performance ecosystem.

---

## 🌟 Architecture & System Highlights

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Connect HR Client App                           │
│     (Flutter Cross-Platform: Android, iOS, Web, Windows Desktop)      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │  HTTPS / JSON / Bearer JWT
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     Dart Shelf REST API Engine                         │
│   (Controllers, Auth Middleware, JWT Signer, Cryptographic Hasher)    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │  Native Mongo Driver / Pool
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Database Layer                                  │
│   (MongoDB Atlas Cloud Database with High-Performance Memory Fallback) │
└────────────────────────────────────────────────────────────────────────┘
```

* **Unified Full-Stack Dart Core:** Single-language architectural synergy sharing clean schemas, serialization models, and type safety between backend and frontend.
* **Granular Role-Based Access Control (RBAC):** Strict operational segregation separating Employee self-service capabilities from HR Administrator governance.
* **Dual Database Resilience:** Direct connection to MongoDB Atlas with an automatic in-memory persistent store fallback for offline and failover continuity.
* **Executive Aesthetics & Material 3:** Modern design system featuring glassmorphic components, high-contrast dark/light modes, interactive charts, and haptic feedback.

---

## 🏢 Core Enterprise Feature Modules

### 1. 💰 Payroll & Compensation Management
* **Digital Salary Slips:** Real-time generation and viewing of monthly itemized payslips (Basic Salary, HRA, Flexible Allowances, PF, Tax Deductions, and Net Disbursed).
* **Official PDF Export & Printing:** On-the-fly client-side compilation of signed, branded salary statements ready for download or direct thermal/laser printing.
* **Transparent CTC Overview:** Transparent visual breakdown of annual Cost-to-Company (CTC), monthly gross earnings, and net take-home pay.
* **HR Payroll Processing:** Batch or individualized compensation generation for active company staff with real-time tax calculation.

### 2. 📍 Smart Attendance & Reception Kiosk
* **Geofenced Perimeter Punch-In:** GPS coordinate validation ensuring check-in/out occurs exclusively within designated office perimeters.
* **Dynamic QR Reception Scanner:** Dynamic, tokenized QR codes generated for office kiosk displays at reception desks for quick employee scanning.
* **Work Hours & Overtime Engine:** Continuous calculation of daily hours worked, monthly cumulative hours, average shifts, and overtime thresholds.
* **Context-Aware Active Shift Monitor:** Dashboard dynamically detects on-duty shifts, displaying live session timers and departure actions.

### 3. 📢 Company Notice Board & Broadcasts
* **Targeted Broadcast Channel:** HR publishing portal for company-wide updates, policy amendments, event notices, and holiday schedules.
* **Notice Tagging & Pinning:** Priority flagging, categorized labels (Policy, Event, Alert, Holiday), and sticky pinned notices.
* **Engagement & Read Tracking:** Individual employee read receipts and unread badge alerts.

### 4. 📊 Expense Claims & Reimbursements
* **Digital Receipt Attachment:** Mobile capture and receipt attachment for travel, meal, client entertainment, and equipment expenses.
* **Multi-Tier Approval Pipeline:** Live claim status tracking (`Pending Review`, `Approved`, `Rejected`, `Reimbursed`).
* **Audit Trail:** Transparent financial reimbursement records for internal accounting.

### 5. 💬 HR Helpdesk & Live Ticketing
* **Dedicated Support Threads:** Category-based ticket generation (Payroll, IT Hardware, Leaves, Workplace Policies).
* **Bi-Directional Support Inbox:** Live interaction between employees and HR administrators with instant message threading.
* **Status Lifecycle:** Step-by-step resolution tracking (`Open`, `In Progress`, `Resolved`, `Closed`).

### 6. 📄 Document Vault & IT Asset Tracker
* **Secure Document Repository:** Employee upload and vault verification for national IDs, tax certificates, academic degrees, and contracts.
* **Company Hardware Inventory:** Comprehensive registry of assigned laptops, monitors, mobile workstations, and peripherals with serial numbers.

### 7. 📈 Advanced HR Analytics & CSV Reporting
* **Interactive Charting:** Department distributions, monthly attendance percentages, and workforce turnover ratios.
* **One-Tap CSV Data Exports:** Instant export of attendance histories and leave logs for payroll ingestion and audit compliance.

### 8. 🔔 Notification Center & Automated Reminders
* **Multi-Channel Alerts:** In-app notification center with category badges and unread counters.
* **Automated Reminders:** Trigger-based notifications for newly issued payslips, approved leave requests, broadcast notices, and ticket updates.

---

## 🛠 Technology Stack

### Frontend Application (Client)
* **Framework:** [Flutter](https://flutter.dev/) (Dart 3.x)
* **State Management:** Provider Architecture (`provider`, `MultiProvider`)
* **Visualization & Reporting:** `fl_chart`, `pdf`, `printing`, `qr_flutter`, `mobile_scanner`
* **Device Services:** `geolocator`, `image_picker`, `flutter_local_notifications`
* **Networking & Storage:** `http`, `shared_preferences`

### Backend Engine (Server)
* **Server Framework:** [Shelf](https://pub.dev/packages/shelf), `shelf_router`, `shelf_cors_headers`
* **Security & Auth:** `dart_jsonwebtoken` (JWT), SHA-256 / Salted PBKDF2 Password Hasher
* **Database Driver:** `mongo_dart` (MongoDB Atlas Native Driver)

---

## 🔒 Security & Data Privacy

* **Zero Plaintext Passwords:** Cryptographically salted SHA-256 and PBKDF2 password hashing.
* **Stateless Bearer JWT Authentication:** Tamper-proof, signed 24-hour expiration tokens verifying `user_id` and role permissions per request.
* **Strict HR Separation:** HR staff profiles are partitioned in separate database collections, ensuring administrative accounts do not mingle with employee records.

---

## 📂 Repository Layout

```
Connect-HRapp/
├── lib/                             # Flutter Cross-Platform Frontend
│   ├── main.dart                    # App Entry & MultiProvider Dependency Tree
│   ├── core/                        # Design Tokens, Colors, Routes, Network Client & Session
│   │   ├── constants/               # API Endpoints & Theme Colors
│   │   ├── network/                 # ApiService & ApiException Interceptor
│   │   ├── routes/                  # AppRoutes Named Route Registry
│   │   ├── services/                # SessionService (Token & Cache Management)
│   │   ├── theme/                   # Material 3 Light & Dark Palettes
│   │   └── utils/                   # PdfGenerator & Helpers
│   ├── models/                      # Strongly-Typed Domain Models (Auth, Payroll, Attendance, etc.)
│   ├── providers/                   # Reactive State Controllers
│   ├── screens/                     # Feature Views (Payroll, Attendance, Vault, Helpdesk, etc.)
│   └── widgets/                     # Reusable UI Atoms (StatusBadges, ActionCards, Dialogs)
├── server/                          # Full-Stack Dart REST API Backend
│   ├── bin/
│   │   ├── server.dart              # Shelf Server Entrypoint & Route Mounting
│   │   └── test_api.dart            # Backend Automated Integration Test Suite
│   ├── lib/
│   │   ├── config/                  # ServerConfig & Environment Parsing
│   │   ├── controllers/             # Feature Controllers (Auth, Payroll, Attendance, etc.)
│   │   ├── db/                      # DatabaseService (MongoDB Atlas + Memory Fallback)
│   │   ├── middleware/              # AuthMiddleware (JWT Verification & RBAC Guards)
│   │   └── utils/                   # PasswordHasher
│   └── pubspec.yaml                 # Backend Dependencies
└── pubspec.yaml                     # Frontend Dependencies
```
