#  France Urban Reporting — Incident Tracking App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

> **Real-time urban incident reporting application for the Lille metropolitan area.**
> Features automated data maintenance, geographic filtering, and high-performance mapping.

---

##  Key Implemented Features

- [x] **Cloud Hosting (Render) :** FastAPI backend deployed on Render for global accessibility without the need for tunneling.
- [x] **Automated Cleanup (Backend):** A Supabase Cron Job (`pg_cron`) automatically deletes expired reports every minute.
- [x] **Geographic Filtering (Bounding Box):** Optimized performance by fetching only incidents visible within the map's viewport.
- [x] **Marker Clustering (Frontend):** Smart grouping of markers to ensure a smooth 120fps experience on modern devices.
- [x] **Real-time Geolocation:** Integrated `geolocator` with automatic user centering and permission management.

---

## Test the Application (Quick Start)

To test the application directly on your Android device without setting up a development environment:

1. **Download: :** [Download APK (v1.0.0)](https://qqgjtgvvsagpokfvrsrc.supabase.co/storage/v1/object/public/app-releases/app-arm64-v8a-release1.apk)
2. **Installation :** Allow installation from "Unknown Sources" in your device settings if prompted.
3. **Note :** The backend is hosted on **Render**, ensuring 24/7 availability for your incident reporting tests.
---

##  Installation & Configuration

### 1. Secret Management (.env)
For security reasons, API keys are not hardcoded. 
1. In both **backend** and **frontend** directories, locate the `.env_example` file.
2. **Action:** Copy these files, rename them to `.env`, and fill in your credentials (Supabase URL, Anon Key, etc.).

### 2. Backend Setup (FastAPI + Supabase)
1. **Install dependencies:** ```bash
   pip install -r requirements.txt
Start the local server: ```bash
uvicorn main:app --reload

Expose the server (Tunneling): To allow the mobile app to access your local machine, run:

Bash
ngrok http 8000
Note: Copy the generated HTTPS URL for the frontend configuration.

3. Frontend Setup (Flutter)
Prerequisites:
Update the API_BASE_URL in your frontend .env with the ngrok URL.

Run flutter pub get.

Option A: Testing on Emulator (PC)
Launch your Android Emulator or iOS Simulator.

The emulator can reach the backend via the ngrok URL or the local alias 10.0.2.2:8000.

Option B: Testing on Physical Device (Recommended)
Tested on Honor Magic 6 Pro for maximum performance:

Setup: Connect your phone via USB Debugging.

Installation: Run flutter run --release.

Connection: The phone must have internet access for the ngrok tunnel to route requests.

Location Settings: Ensure "Google Location Accuracy" is enabled in your phone's settings for an instant GPS fix.

 Technical Stack
Layer	Technology
Frontend	Flutter (flutter_map, geolocator, marker_cluster)
Backend	FastAPI (Python)
Database	Supabase (PostgreSQL + PostGIS)
Automation	pg_cron extension for DB maintenance
 Team Note
Timezone Reminder: The Supabase server operates on UTC time. Test incidents created locally might appear with a 1-hour offset compared to French local time. The automated cleanup script (cron) handles this offset correctly.



##  Authors

* **[Sarah Wacquiez]**
* **[Christophe Saniez-Lenthieul]**
