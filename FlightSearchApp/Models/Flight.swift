import Foundation

struct Flight: Identifiable, Hashable {
    let id: UUID
    let airline: String
    let flightNumber: String
    let origin: String
    let destination: String
    let departureDate: Date
    let arrivalDate: Date
    let durationMinutes: Int
    let price: Double
    let layovers: [String]

    init(
        id: UUID = UUID(),
        airline: String,
        flightNumber: String,
        origin: String,
        destination: String,
        departureDate: Date,
        arrivalDate: Date,
        durationMinutes: Int,
        price: Double,
        layovers: [String] = []
    ) {
        self.id = id
        self.airline = airline
        self.flightNumber = flightNumber
        self.origin = origin
        self.destination = destination
        self.departureDate = departureDate
        self.arrivalDate = arrivalDate
        self.durationMinutes = durationMinutes
        self.price = price
        self.layovers = layovers
    }
}

