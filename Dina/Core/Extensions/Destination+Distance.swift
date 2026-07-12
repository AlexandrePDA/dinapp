import CoreLocation

extension Array where Element == Destination {
    /// Somme des distances entre étapes consécutives, en kilomètres.
    /// Le tableau doit être ordonné par date de visite.
    var totalTraveledKilometers: Double {
        guard count > 1 else { return 0 }
        var total: CLLocationDistance = 0
        for index in 1..<count {
            let previous = CLLocation(latitude: self[index - 1].latitude, longitude: self[index - 1].longitude)
            let current = CLLocation(latitude: self[index].latitude, longitude: self[index].longitude)
            total += current.distance(from: previous)
        }
        return total / 1000
    }
}

extension Double {
    /// « 0 km », « 42 km » — pour l'affichage des distances cumulées.
    var kilometersLabel: String {
        self < 1 ? "0 km" : String(format: "%.0f km", self)
    }
}
