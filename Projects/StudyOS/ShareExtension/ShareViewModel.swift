import Core
import Storage
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

@MainActor
final class ShareViewModel: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var courses: [Course] = []
    @Published var assignments: [Assignment] = []
    @Published var selectedProfileId: UUID?
    @Published var selectedCourseId: UUID?
    @Published var selectedAssignmentId: UUID?
    @Published var shareItem: ShareItem?
    @Published var statusMessage: String?
    @Published var isSaving = false

    let modelContext: ModelContext
    private let extensionContext: NSExtensionContext?

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
        let configuration = StorageConfiguration(
            appGroupId: AppConstants.appGroupId,
            cloudKitContainerId: AppConstants.cloudKitContainerId,
            useCloudKit: false
        )
        let container = try! StorageController.makeContainer(models: StorageModels.all, configuration: configuration)
        self.modelContext = ModelContext(container)
    }

    func load() {
        profiles = (try? modelContext.fetch(FetchDescriptor<Profile>())) ?? []
        courses = (try? modelContext.fetch(FetchDescriptor<Course>())) ?? []
        assignments = (try? modelContext.fetch(FetchDescriptor<Assignment>())) ?? []
        selectedProfileId = profiles.first?.id
        selectedCourseId = courses.first?.id
        Task { await loadShareItem() }
    }

    var assignmentsForSelectedCourse: [Assignment] {
        guard let courseId = selectedCourseId else { return [] }
        return assignments.filter { $0.course?.id == courseId }
    }

    func save() async {
        guard let shareItem else {
            statusMessage = "No share item found."
            return
        }
        guard let courseId = selectedCourseId,
              let course = courses.first(where: { $0.id == courseId }) else {
            statusMessage = "Select a course first."
            return
        }
        let assignment = assignmentsForSelectedCourse.first { $0.id == selectedAssignmentId }

        isSaving = true
        defer { isSaving = false }

        switch shareItem.content {
        case .url(let url):
            saveLink(url.absoluteString, course: course, assignment: assignment)
        case .text(let text):
            saveNote(text, course: course, assignment: assignment)
        case .image(let image):
            saveImage(image, course: course, assignment: assignment)
        case .file(let url):
            saveFile(url, course: course, assignment: assignment)
        }

        statusMessage = "Saved"
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "Share", code: 1))
    }

    private func loadShareItem() async {
        guard let itemProvider = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = itemProvider.attachments?.first else {
            return
        }

        do {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                let url = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier)
                shareItem = ShareItem(title: url.absoluteString, content: .url(url))
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                let image = try await provider.loadImage()
                shareItem = ShareItem(title: "Image", content: .image(image))
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                let url = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier)
                shareItem = ShareItem(title: url.lastPathComponent, content: .file(url))
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                let text = try await provider.loadText()
                shareItem = ShareItem(title: text, content: .text(text))
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func saveLink(_ url: String, course: Course, assignment: Assignment?) {
        let data = Data(url.utf8)
        let reference = FileReference(
            name: url,
            bookmarkData: data,
            type: .link,
            createdAt: Date(),
            course: course,
            assignment: assignment
        )
        modelContext.insert(reference)
        try? modelContext.save()
    }

    private func saveNote(_ text: String, course: Course, assignment: Assignment?) {
        let note = NoteItem(
            title: "Shared Note",
            content: text,
            ocrText: text,
            createdAt: Date(),
            course: course,
            assignment: assignment
        )
        modelContext.insert(note)
        try? modelContext.save()
    }

    private func saveImage(_ image: UIImage, course: Course, assignment: Assignment?) {
        guard let data = image.pngData() else { return }
        let url = storeSharedFile(data: data, fileExtension: "png")
        saveFile(url, course: course, assignment: assignment)
    }

    private func saveFile(_ url: URL, course: Course, assignment: Assignment?) {
        let target = copyToSharedContainer(url: url)
        guard let bookmark = try? target.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return
        }
        let type = resolveType(url: target)
        let reference = FileReference(
            name: target.lastPathComponent,
            bookmarkData: bookmark,
            type: type,
            createdAt: Date(),
            course: course,
            assignment: assignment
        )
        modelContext.insert(reference)
        try? modelContext.save()
    }

    private func storeSharedFile(data: Data, fileExtension: String) -> URL {
        let directory = sharedItemsDirectory()
        let fileURL = directory.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
        try? data.write(to: fileURL)
        return fileURL
    }

    private func copyToSharedContainer(url: URL) -> URL {
        let directory = sharedItemsDirectory()
        let destination = directory.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: destination.path) {
            return destination
        }
        try? FileManager.default.copyItem(at: url, to: destination)
        return destination
    }

    private func sharedItemsDirectory() -> URL {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupId) ?? FileManager.default.temporaryDirectory
        let directory = containerURL.appendingPathComponent("SharedItems", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func resolveType(url: URL) -> FileReferenceType {
        if let type = UTType(filenameExtension: url.pathExtension) {
            if type.conforms(to: .pdf) { return .pdf }
            if type.conforms(to: .image) { return .image }
        }
        return .other
    }
}

struct ShareItem {
    let title: String
    let content: ShareContent
}

enum ShareContent {
    case url(URL)
    case text(String)
    case image(UIImage)
    case file(URL)
}

private extension NSItemProvider {
    func loadItem(forTypeIdentifier identifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(domain: "Share", code: 2))
                }
            }
        }
    }

    func loadText() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let text = item as? String {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(throwing: NSError(domain: "Share", code: 3))
                }
            }
        }
    }

    func loadImage() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let image = item as? UIImage {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: NSError(domain: "Share", code: 4))
                }
            }
        }
    }
}
