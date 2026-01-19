import Storage
import SwiftData
import SwiftUI
import UIComponents
import UniformTypeIdentifiers
import VisionKit

struct CourseVaultDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Bindable var course: Course
    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]

    @State private var showFileImporter = false
    @State private var showScanner = false
    @State private var showScannerUnavailable = false
    @State private var showAddLink = false
    @State private var selectedAssignmentId: UUID?
    @State private var linkURL: String = ""

    private var courseAssignments: [Assignment] {
        assignments.filter { $0.course?.id == course.id }
    }

    var body: some View {
        List {
            Section("Attach to assignment") {
                Picker("Assignment", selection: $selectedAssignmentId) {
                    Text("None").tag(UUID?.none)
                    ForEach(courseAssignments) { assignment in
                        Text(assignment.title).tag(UUID?.some(assignment.id))
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Notes") {
                if course.notes.isEmpty {
                    Text("No notes yet")
                        .font(StudyTypography.caption)
                        .foregroundColor(StudyColor.secondaryText)
                }
                ForEach(course.notes.sorted(by: { $0.createdAt > $1.createdAt })) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title)
                            .font(StudyTypography.headline)
                        Text(note.content)
                            .font(StudyTypography.caption)
                            .foregroundColor(StudyColor.secondaryText)
                            .lineLimit(2)
                    }
                }
            }

            Section("Files") {
                if course.files.isEmpty {
                    Text("No files yet")
                        .font(StudyTypography.caption)
                        .foregroundColor(StudyColor.secondaryText)
                }
                ForEach(course.files.sorted(by: { $0.createdAt > $1.createdAt })) { file in
                    Button {
                        openFile(file)
                    } label: {
                        HStack {
                            Image(systemName: iconName(for: file.type))
                            Text(file.name)
                                .font(StudyTypography.body)
                        }
                    }
                }
            }
        }
        .navigationTitle(course.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Import File") {
                        showFileImporter = true
                    }
                    Button("Scan Note") {
                        if VNDocumentCameraViewController.isSupported {
                            showScanner = true
                        } else {
                            showScannerUnavailable = true
                        }
                    }
                    Button("Add Link") {
                        showAddLink = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.data]) { result in
            switch result {
            case .success(let url):
                importFile(url)
            case .failure:
                break
            }
        }
        .sheet(isPresented: $showScanner) {
            DocumentScannerView { text in
                addScannedNote(text)
            }
        }
        .alert("Scanner unavailable", isPresented: $showScannerUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Document scanning is not supported on this device.")
        }
        .alert("Add Link", isPresented: $showAddLink) {
            TextField("https://...", text: $linkURL)
            Button("Save") {
                addLink()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func importFile(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            let fileType = resolveType(url: url)
            let assignment = courseAssignments.first { $0.id == selectedAssignmentId }
            let reference = FileReference(
                name: url.lastPathComponent,
                bookmarkData: bookmark,
                type: fileType,
                createdAt: Date(),
                course: course,
                assignment: assignment
            )
            modelContext.insert(reference)
            try modelContext.save()
        } catch {
            return
        }
    }

    private func addScannedNote(_ text: String) {
        let assignment = courseAssignments.first { $0.id == selectedAssignmentId }
        let note = NoteItem(
            title: "Scanned Note",
            content: text,
            ocrText: text,
            createdAt: Date(),
            course: course,
            assignment: assignment
        )
        modelContext.insert(note)
        try? modelContext.save()
    }

    private func addLink() {
        let trimmed = linkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let assignment = courseAssignments.first { $0.id == selectedAssignmentId }
        let data = Data(trimmed.utf8)
        let reference = FileReference(
            name: trimmed,
            bookmarkData: data,
            type: .link,
            createdAt: Date(),
            course: course,
            assignment: assignment
        )
        modelContext.insert(reference)
        linkURL = ""
        try? modelContext.save()
    }

    private func openFile(_ file: FileReference) {
        if file.type == .link, let url = URL(string: file.name) {
            openURL(url)
            return
        }
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: file.bookmarkData, options: [.withSecurityScope], bookmarkDataIsStale: &isStale) {
            if url.startAccessingSecurityScopedResource() {
                openURL(url)
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    private func resolveType(url: URL) -> FileReferenceType {
        if let type = UTType(filenameExtension: url.pathExtension) {
            if type.conforms(to: .pdf) { return .pdf }
            if type.conforms(to: .image) { return .image }
        }
        return .other
    }

    private func iconName(for type: FileReferenceType) -> String {
        switch type {
        case .pdf: return "doc.richtext"
        case .image: return "photo"
        case .link: return "link"
        case .other: return "doc"
        }
    }
}
