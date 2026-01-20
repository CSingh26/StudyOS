import CloudKit
import Foundation
import Storage

protocol CollaborationStore {
    func saveAvailability(_ block: AvailabilityBlock) async throws
    func saveGroupProject(_ project: GroupProject) async throws
    func saveMilestone(_ milestone: Milestone, project: GroupProject) async throws
    func createShare(for project: GroupProject) async throws -> CKShare
}

final class CloudKitCollaborationStore: CollaborationStore {
    private let container: CKContainer
    private let database: CKDatabase

    init(containerId: String) {
        self.container = CKContainer(identifier: containerId)
        self.database = container.privateCloudDatabase
    }

    func saveAvailability(_ block: AvailabilityBlock) async throws {
        let record = CKRecord(recordType: "AvailabilityBlock")
        record["startDate"] = block.startDate as CKRecordValue
        record["endDate"] = block.endDate as CKRecordValue
        record["profileId"] = block.profile?.id.uuidString as CKRecordValue?
        _ = try await database.save(record)
    }

    func saveGroupProject(_ project: GroupProject) async throws {
        let record = CKRecord(recordType: "GroupProject")
        record["title"] = project.title as CKRecordValue
        record["notes"] = project.notes as CKRecordValue
        record["createdAt"] = project.createdAt as CKRecordValue
        record["profileId"] = project.profile?.id.uuidString as CKRecordValue?
        _ = try await database.save(record)
    }

    func saveMilestone(_ milestone: Milestone, project: GroupProject) async throws {
        let record = CKRecord(recordType: "Milestone")
        record["title"] = milestone.title as CKRecordValue
        record["dueDate"] = milestone.dueDate as CKRecordValue
        record["isCompleted"] = milestone.isCompleted as CKRecordValue
        record["projectId"] = project.id.uuidString as CKRecordValue
        _ = try await database.save(record)
    }

    func createShare(for project: GroupProject) async throws -> CKShare {
        let projectRecord = CKRecord(recordType: "GroupProject")
        projectRecord["title"] = project.title as CKRecordValue
        projectRecord["notes"] = project.notes as CKRecordValue
        projectRecord["createdAt"] = project.createdAt as CKRecordValue
        projectRecord["profileId"] = project.profile?.id.uuidString as CKRecordValue?

        let share = CKShare(rootRecord: projectRecord)
        share[CKShare.SystemFieldKey.title] = project.title as CKRecordValue

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let operation = CKModifyRecordsOperation(recordsToSave: [projectRecord, share], recordIDsToDelete: nil)
            operation.modifyRecordsCompletionBlock = { _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
            database.add(operation)
        }

        return share
    }
}
