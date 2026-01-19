import SwiftData

public enum StorageModels {
    public static let all: [any PersistentModel.Type] = [
        Profile.self,
        Course.self,
        Assignment.self,
        Quiz.self,
        Announcement.self,
        Grade.self,
        CalendarEvent.self,
        StudyBlock.self,
        FocusSession.self,
        NoteItem.self,
        FileReference.self,
        Template.self,
        Subtask.self,
        AvailabilityBlock.self,
        GroupProject.self,
        Milestone.self
    ]
}
