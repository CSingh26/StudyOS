import OSLog

public enum LogCategory: String {
    case sync
    case planner
    case storage
    case ui
    case canvas
    case general
}

public enum StudyLogger {
    public static let subsystem = "com.studyos.app"

    public static let sync = Logger(subsystem: subsystem, category: LogCategory.sync.rawValue)
    public static let planner = Logger(subsystem: subsystem, category: LogCategory.planner.rawValue)
    public static let storage = Logger(subsystem: subsystem, category: LogCategory.storage.rawValue)
    public static let ui = Logger(subsystem: subsystem, category: LogCategory.ui.rawValue)
    public static let canvas = Logger(subsystem: subsystem, category: LogCategory.canvas.rawValue)
    public static let general = Logger(subsystem: subsystem, category: LogCategory.general.rawValue)
}
