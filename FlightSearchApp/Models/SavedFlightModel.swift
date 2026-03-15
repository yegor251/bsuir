import Foundation
import CoreData

struct SavedFlightModel: Identifiable, Hashable {
    let id: UUID
    let flightNumber: String
    let airline: String
    let origin: String
    let destination: String
    let departureDate: Date
    let arrivalDate: Date
    let price: Double
    let savedDate: Date
    var notes: String?
    var title: String?
    var notes2: String?
    var photoPath: String?

    init(
        id: UUID,
        flightNumber: String,
        airline: String,
        origin: String,
        destination: String,
        departureDate: Date,
        arrivalDate: Date,
        price: Double,
        savedDate: Date,
        notes: String? = nil,
        title: String? = nil,
        notes2: String? = nil,
        photoPath: String? = nil
    ) {
        self.id = id
        self.flightNumber = flightNumber
        self.airline = airline
        self.origin = origin
        self.destination = destination
        self.departureDate = departureDate
        self.arrivalDate = arrivalDate
        self.price = price
        self.savedDate = savedDate
        self.notes = notes
        self.title = title
        self.notes2 = notes2
        self.photoPath = photoPath
    }

    init?(entity: NSManagedObject) {
        guard
            let id = entity.value(forKey: "id") as? UUID,
            let flightNumber = entity.value(forKey: "flightNumber") as? String,
            let airline = entity.value(forKey: "airline") as? String,
            let origin = entity.value(forKey: "origin") as? String,
            let destination = entity.value(forKey: "destination") as? String,
            let departureDate = entity.value(forKey: "departureDate") as? Date,
            let arrivalDate = entity.value(forKey: "arrivalDate") as? Date,
            let savedDate = entity.value(forKey: "savedDate") as? Date,
            let price = entity.value(forKey: "price") as? Double
        else {
            return nil
        }

        self.id = id
        self.flightNumber = flightNumber
        self.airline = airline
        self.origin = origin
        self.destination = destination
        self.departureDate = departureDate
        self.arrivalDate = arrivalDate
        self.price = price
        self.savedDate = savedDate
        self.notes = entity.value(forKey: "notes") as? String
        self.title = entity.value(forKey: "title") as? String
        self.notes2 = entity.value(forKey: "notes2") as? String
        self.photoPath = entity.value(forKey: "photoPath") as? String
    }
}

