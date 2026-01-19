# Data Model

StudyOS uses SwiftData models scoped by profile. Relationships are modeled with SwiftData `@Relationship`.

## Entities
- **Profile**: name, demo flag, Canvas config, iCal feed, sync timestamps.
- **Course**: name, code, color, Canvas ID, grades settings.
- **Assignment**: title, due date, status, weight, submission type, Canvas link.
- **Quiz**: title, due date, points, Canvas link.
- **Announcement**: title, message, posted date, Canvas link.
- **Grade**: title, score, weight, manual flag.
- **CalendarEvent**: start/end, location, source, Canvas ID.
- **StudyBlock**: planned sessions tied to assignments/courses.
- **FocusSession**: logged time, duration, notes.
- **NoteItem**: user notes + OCR text.
- **FileReference**: bookmark data to file, type, course/assignment linkage.
- **Template/Subtask**: task breakdown templates.
- **AvailabilityBlock**: study group scheduling availability.
- **GroupProject/Milestone**: collaboration board data.
