# 🚀 ZoomAutoJoiner — Developer Notes  
_Last updated: 22nd Nov 2025 @ 4:27 PM_

---

## ✅ Current Progress (Working Features)

### 🎉 Fully Working Core System
- Automatic Zoom meeting opener and joiner is **fully functional**
- App correctly:
  - Parses Zoom URLs
  - Validates Meeting IDs
  - Opens Zoom
  - Joins meetings without user interaction
- Core models finished:
  - `Meeting`
  - `MeetingMode`
  - `MeetingSource`
  - `MeetingNotes`
  - `AppSettings`

### 🔧 Major Bug Fixes Completed
- Fixed **meeting ID truncation** issue  
- Fixed **invalid URL parsing**  
- Fixed **invalid meeting ID input handling**  
- Improved validation for:
  - numeric ID inputs  
  - Zoom URL formats  
  - embedded Zoom links  

### 🗂️ User Interface & Features
- Added **Upcoming Meetings** tab  
- Added **Past Meetings** tab  
- Incognito mode fully implemented  
  - User can choose whether the app joins silently or visibly  
- Added setting for **“Save Notes?”**  
  - User chooses whether to save notes after each meeting

### 🔐 Back-End Architecture
- Secure credential storage using **KeychainManager**
- Meeting scheduling system implemented via **MeetingScheduler**
- Local persistence handled by **PersistenceService**
- Built a fully modular **Services layer**, including:
  - `ZoomService`
  - `CalendarService`
  - `GoogleCalendarService`
  - `OpenAIService`
  - `AudioCaptureService`
  - `ScreenCaptureService`
  - `ZoomAutomationService`
  - `LiveAudioCaptureService`
  - `LiveAssistantService`

### 🟣 Early Prototype Features (Working but WIP)
- Floating Assistant window (initial framework in place)
- Assistant subsystem is structured:
  - Live transcript ingestion (partial)
  - Live note-taking (partial)
  - Assistant message model created
- Floating assistant acts as a **standalone module** inside the app
- UI foundation created:
  - `MainView`
  - `ManualMeetingView`
  - `MeetingListView`
  - `MeetingDetailView`
  - `SettingsView`

---

## 🧪 Experimental (Work In Progress)

### 🟣 Floating Assistant (High Priority)
- Basic SwiftUI window created  
- Acts as a draggable floating UI element (partial)  
- Will show:
  - Real-time transcript  
  - Assistant messages  
  - Controls for audio, pin, expand  
  - AI-generated notes summary  

### 🟣 Live Notes Integration (OpenAI)
- Audio capture pipeline partly working  
- Whisper/Realtime integration framework set up  
- Needs full connection:
  - mic → buffer → OpenAI → transcript → assistant → UI

---

## 📌 To-Do List (Next Steps)

### 🖥️ Floating Assistant UI  
- [ ] Complete draggable floating window logic  
- [ ] Add transcript view with auto-scrolling  
- [ ] Add chat interface (bubbles + layout)  
- [ ] Add assistant message styling  
- [ ] Add minimized mode  
- [ ] Add animated open/close transitions  
- [ ] Add dark/light mode  
- [ ] Integrate assistant audio → transcript → UI display  

### 📝 Notes System  
- [ ] Let user **edit AI-generated meeting notes**  
- [ ] Add “Save as Category” UI  
- [ ] Add ability to **tag meetings** with custom categories  
- [ ] Add note-search functionality  
- [ ] Add share/export (PDF, .txt)  
- [ ] Add note merge for multi-session meetings  

### ⚙️ Settings  
- [ ] Add toggle for Incognito mode in Settings  
- [ ] Add toggle for automatic note saving  
- [ ] Add OpenAI API key UI  
- [ ] Add model selection (gpt-4.1, 4o-mini, Realtime etc.)

### 📅 Calendar Integration  
- [ ] Improve event conflict detection  
- [ ] Add manual refresh control  
- [ ] Improve Google authentication flow  
- [ ] Allow linking multiple Google accounts  

### 🧱 System Reliability  
- [ ] Add better error handling for Zoom automation failures  
- [ ] Build retry logic for OpenAI streaming  
- [ ] Add verbose logging for debugging  
- [ ] Add fallback if Zoom fails to launch  

---

## 📐 Architecture Overview

### Folder Structure
- **Models** — data models (Meeting, Settings, Notes, etc.)  
- **ViewModels** — logical binders for the UI  
- **Views** — SwiftUI UI layer  
- **Managers** — Keychain, Notification, Scheduling  
- **Services** — Zoom, Calendar, Audio, OpenAI, Persistence  
- **Utilities** — constants, extensions, helpers  
- **Resources** — assets, entitlements, configs  

### Entitlements & Permissions  
- App Sandbox: On  
- Hardened Runtime: On  
- Microphone access: Enabled  
- Calendar access: Enabled  
- File read access: Enabled  
- Outgoing connections: Enabled  

---

## 💡 Future Ideas (Long-Term)
- Smart meeting summarizer  
- Automatic action item extraction  
- Multi-language support for notes  
- Siri Shortcuts integration  
- Cloud sync (iCloud Drive or custom backend)  
- Desktop widget with upcoming meetings  

---

## ✨ TL;DR Status Summary

You currently have a **working core product**:

✔ Auto joins Zoom  
✔ Validates meeting IDs + URLs  
✔ Syncs calendar events  
✔ Saves notes (optional)  
✔ Incognito mode  
✔ Upcoming + Past meeting tabs  
✔ Floating assistant foundation  
✔ Major parsing bugs fixed  
✔ Audio + AI pipeline partially working  

The next major step is **finishing UI for floating window + chat interface**.

---



