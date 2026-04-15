# GPS Dog Collar
Includes database code and Arduino code for the collars.
The server uses a Linux Ubuntu server available here https://ubuntu.com/download/server.
The app was created in order to avoid subscriptions services from off the shelf models. 
The app is an iOS app.
I will upload everything I did including the 3D printing files for people to copy.
This system architecture works by using the pi as a middle point. The collar sends periodic updates to the pi and the iOS app connects to the pi and receives information from it. As well as sending information back.

**collar -> pi <-> iOS app**

## Hardware 
- Raspberry Pi 32g
- Raspberry Pi Picco
- SIM7000 (Sends packets using cell towers and has an in built gps module)

## Folder Layout 
- Arduino Module: Contains Code for the pico
- 3D Print Files : Contains the CAD and STP files for the collar case
- GPS Tracker.xcodeproj: Contains the project file for XCode
- GPS Tracker: Contains the swift files associated with the project
- GPS TrackerUITest is empty 
- Server Downloads contains all of the server files along with the database and FastAPI code
