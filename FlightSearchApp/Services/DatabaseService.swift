import Foundation
import CoreData

protocol DatabaseServiceProtocol {
    func saveFlight(_ flight: Flight, notes: String?, title: String?, notes2: String?) throws
    func fetchSavedFlights() throws -> [SavedFlightModel]
    func deleteFlight(id: UUID) throws
    func updateSavedFlight(id: UUID, notes: String?, title: String?, notes2: String?) throws
    func updateSavedFlightPhoto(id: UUID, photoPath: String?) throws
}

final class DatabaseService: DatabaseServiceProtocol {
    static let shared = DatabaseService()

    private let container: NSPersistentContainer

    private init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    private var context: NSManagedObjectContext {
        container.viewContext
    }

    func saveFlight(_ flight: Flight, notes: String?, title: String?, notes2: String?) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedFlight")
        request.predicate = NSPredicate(format: "id == %@", flight.id as CVarArg)
        let existing = try context.fetch(request)

        let entity: NSManagedObject
        if let first = existing.first {
            entity = first
        } else {
            entity = NSEntityDescription.insertNewObject(forEntityName: "SavedFlight", into: context)
        }

        entity.setValue(flight.id, forKey: "id")
        entity.setValue(flight.flightNumber, forKey: "flightNumber")
        entity.setValue(flight.airline, forKey: "airline")
        entity.setValue(flight.origin, forKey: "origin")
        entity.setValue(flight.destination, forKey: "destination")
        entity.setValue(flight.departureDate, forKey: "departureDate")
        entity.setValue(flight.arrivalDate, forKey: "arrivalDate")
        entity.setValue(flight.price, forKey: "price")
        entity.setValue(Date(), forKey: "savedDate")
        entity.setValue(notes, forKey: "notes")
        entity.setValue(title, forKey: "title")
        entity.setValue(notes2, forKey: "notes2")
        try context.save()
    }

    func fetchSavedFlights() throws -> [SavedFlightModel] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedFlight")
        request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
        let results = try context.fetch(request)
        

        let models = results.compactMap { SavedFlightModel(entity: $0) }
        
        var seen = Set<UUID>()
        return models.filter { seen.insert($0.id).inserted }
    }

    func deleteFlight(id: UUID) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedFlight")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(request)
        results.forEach(context.delete)
        try context.save()
    }

    func updateSavedFlight(id: UUID, notes: String?, title: String?, notes2: String?) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedFlight")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let entity = try context.fetch(request).first {
            entity.setValue(notes, forKey: "notes")
            entity.setValue(title, forKey: "title")
            entity.setValue(notes2, forKey: "notes2")
            try context.save()
        }
    }

    func updateSavedFlightPhoto(id: UUID, photoPath: String?) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedFlight")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let entity = try context.fetch(request).first {
            entity.setValue(photoPath, forKey: "photoPath")
            try context.save()
        }
    }
}

