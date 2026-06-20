`auth_service.dart` Handles user **sign up**, **sign in**, **sign out**, and **getting the current user's info**. Uses Supabase Auth which manages passwords securely.
`loan_service.dart` Handles **applying for loans**, **viewing loan history**, **checking pending loans**, and admin actions like **approving/rejecting** loans. Also includes **AI evaluation** results.
`wallet_service.dart` Handles the e-wallet: **checking balance**, **viewing payment history**, **auto-deduction logs**, **top-up**, and **withdrawal**.
`profile_service.dart` Handles **fetching** and **updating** the user's profile information (name, course, contact number, etc.).
`notification_service.dart` Handles **fetching notifications**, **marking individual notifications as read**, and **marking all as read**.

<!-- Tech Stack -->

Flutter | Mobile app framework (UI)  
Dart | Programming language  
Supabase | Backend (auth, database, storage)
PostgreSQL | Database engine (used by Supabase)
