# StudyOS

StudyOS is an iOS-only study organizer focused on offline-first workflows, privacy, and accessibility. It syncs Canvas when available, imports iCal calendars, and helps you plan, execute, and review your week.

## Quick Start
```bash
./Scripts/bootstrap.sh
./Scripts/generate.sh
open StudyOS.xcworkspace
./Scripts/run_tests.sh
```

## Demo Mode
- Launch the app and follow onboarding.
- Choose **Demo** mode to seed offline data.
- The app works fully offline in demo mode.

## Canvas OAuth Setup
1. Create a Canvas Developer Key.
2. Set a redirect URI like `studyos://oauth/callback`.
3. In StudyOS Settings, enter:
   - Base URL (e.g., `https://school.instructure.com`)
   - Client ID
   - Redirect URI
   - Scopes (default: `url:GET|/api/v1/*`)
4. Tap **Connect Canvas**.
5. If OAuth is not possible, enable **Limited Mode** and use iCal/manual tasks.

## iCal Import
- Import a local `.ics` file from the Calendar tab.
- Or subscribe to a feed URL and refresh manually or via background sync.

## Features
- Canvas sync for courses, assignments, quizzes, announcements, grades, and events.
- Offline-first SwiftData cache with background refresh.
- Smart planning with priority scoring and routine constraints.
- Focus sessions with live activities and widgets.
- Vault for class files, scans (OCR), and global search.
- Share Extension for saving links/images/documents into a course.
- App lock with Face ID / Touch ID and data export (JSON/CSV).

## Screenshots
Add screenshots to `Docs/Screenshots/` and update links below:
- `Docs/Screenshots/today.png`
- `Docs/Screenshots/assignments.png`
- `Docs/Screenshots/calendar.png`
- `Docs/Screenshots/vault.png`

## Notes
- Requires Xcode 15+ and iOS 17+.
- App Group ID: `group.com.studyos.app`.
- CloudKit container: `iCloud.com.studyos.app` (optional).
