# GPS Dog Collar

A DIY GPS tracking system for dogs, built to avoid the recurring subscription fees of off-the-shelf trackers. The system pairs custom Arduino-based collar hardware with a Raspberry Pi server and a native iOS app.

## How It Works

The collar periodically transmits its GPS location over the cellular network to a Raspberry Pi acting as the central server. The iOS app connects to the Pi to display real-time location data, manage geofences, and receive alerts.

```
Collar (SIM7000 + Pico) ---cellular---> Raspberry Pi <---HTTP---> iOS App
```

## Hardware

- **Raspberry Pi** — Runs the FastAPI backend and SQLite database
- **Raspberry Pi Pico** — Microcontroller on the collar
- **SIM7000** — Cellular + GPS module; transmits location data via cell towers
- **3D-printed enclosure** — Custom collar case (CAD/STP files included)

## Software

- **iOS App** — Built with Swift and UIKit. Features include live map tracking, geofence creation (MKPolygon/MapKit), and push notifications.
- **Backend** — Python FastAPI server with SQLite, handling location ingestion and geofence logic.
- **Arduino Module** — C++ firmware for the Pico, parsing GPS data from the SIM7000 via AT commands.

## Repository Structure

```
├── Arduino Module/        # Pico firmware (C++)
├── 3D Print Files/        # CAD and STP files for the collar case
├── GPS Tracker.xcodeproj  # Xcode project file
├── GPS Tracker/           # Swift source files for the iOS app
└── Server Downloads/      # FastAPI server, database, and related files
```

## Getting Started

### Server

1. Set up a Raspberry Pi with [Ubuntu Server](https://ubuntu.com/download/server).
2. Install Python 3 and the required dependencies:
   ```bash
   pip install fastapi uvicorn sqlalchemy
   ```
3. Run the server:
   ```bash
   uvicorn main:app --host 0.0.0.0
   ```

### iOS App

1. Open `GPS Tracker.xcodeproj` in Xcode.
2. Update the server URL to point to your Pi's IP address.
3. Build and run on a physical device (GPS requires real hardware).

### Collar

1. Flash the Arduino module code to the Raspberry Pi Pico.
2. Wire the SIM7000 module to the Pico.
3. Insert a SIM card with an active data plan.
4. Print the enclosure using the files in `3D Print Files/`.

## Why DIY?

Commercial GPS collars typically require monthly subscriptions of $5–15+. This project gives you full ownership of the hardware and software with no ongoing costs beyond a cheap data-only SIM plan.

## License

<!-- Add your preferred license here, e.g. MIT -->
