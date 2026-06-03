# How to Run Your Vibe-Coded Connect App

Since we just built this app together, here is exactly how you can run and test your creation on your machine right now.

## 1. Start Your Flask Backend

The backend needs to be running so the Android app has a database to talk to.

1. Open a new terminal in VS Code (or your command prompt).
2. Navigate to the backend folder:
   ```bash
   cd d:\HRApp\backend
   ```
3. Activate the virtual environment we created:
   ```bash
   .\venv\Scripts\activate
   ```
4. Start the server:
   ```bash
   python app.py
   ```
*Leave this terminal window open and running! Your API is now live at `http://127.0.0.1:5000`.*

---

## 2. Launch Your Android App

Now that the backend is up, let's run the actual mobile app.

### The Easiest Way: Android Studio
1. Open **Android Studio**.
2. Click **Open** and select the `d:\HRApp\android-app` folder. 
3. Let it sync for a minute (you'll see a loading bar at the bottom).
4. In the top toolbar, select your emulator (like the `Pixel_9a` we were using) from the dropdown.
5. Click the green **Play (Run)** button. 
6. The emulator will boot up, install the app, and open it automatically. 

*Note: The app is configured to talk to `10.0.2.2`, which is the special IP address the Android emulator uses to securely connect back to your running Flask server on localhost.*

### What to Test First
Once the app opens on the emulator:
1. Click **"Don't have an account? Sign up"**.
2. Enter a test name, email, and password, and hit **Sign Up**. (This will write a new employee document to your MongoDB Atlas database!).
3. Log in with those exact credentials.
4. You'll hit the **Employee Dashboard**! Click "Punch In" to log your first attendance record directly to the database.
