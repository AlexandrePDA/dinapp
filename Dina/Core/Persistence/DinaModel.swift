import CoreData

/// Modèle Core Data construit en code, en parité exacte avec l'ancien
/// schéma SwiftData : mêmes entités, attributs et relations. Cette parité
/// permet de rouvrir le store existant et de conserver les types
/// d'enregistrements CloudKit (CD_*) déjà déployés.
///
/// Règles CloudKit respectées : tout attribut non optionnel a une valeur
/// par défaut, toutes les relations sont optionnelles avec inverse.
enum DinaModel {
    @MainActor static let shared: NSManagedObjectModel = build()

    private static func build() -> NSManagedObjectModel {
        // MARK: Entités

        let family = entity("Family", class: Family.self, attributes: [
            attribute("identifier", .UUIDAttributeType, defaultValue: UUID()),
            attribute("title", .stringAttributeType, defaultValue: "Ma famille"),
            attribute("createdAt", .dateAttributeType, defaultValue: Date())
        ])

        let baby = entity("BabyProfile", class: BabyProfile.self, attributes: [
            attribute("identifier", .UUIDAttributeType, defaultValue: UUID()),
            attribute("name", .stringAttributeType, defaultValue: ""),
            attribute("birthDate", .dateAttributeType, defaultValue: Date()),
            attribute("createdAt", .dateAttributeType, defaultValue: Date())
        ])

        let trip = entity("Trip", class: Trip.self, attributes: [
            attribute("identifier", .UUIDAttributeType, defaultValue: UUID()),
            attribute("title", .stringAttributeType, defaultValue: ""),
            attribute("startDate", .dateAttributeType, defaultValue: Date()),
            attribute("endDate", .dateAttributeType, optional: true),
            attribute("createdAt", .dateAttributeType, defaultValue: Date())
        ])

        let destination = entity("Destination", class: Destination.self, attributes: [
            attribute("identifier", .UUIDAttributeType, defaultValue: UUID()),
            attribute("placeName", .stringAttributeType, defaultValue: ""),
            attribute("subtitle", .stringAttributeType, defaultValue: ""),
            attribute("latitude", .doubleAttributeType, defaultValue: 0.0),
            attribute("longitude", .doubleAttributeType, defaultValue: 0.0),
            attribute("visitDate", .dateAttributeType, defaultValue: Date()),
            attribute("departureDate", .dateAttributeType, optional: true),
            attribute("purposeRaw", .stringAttributeType, defaultValue: TripPurpose.weekend.rawValue),
            attribute("notes", .stringAttributeType, defaultValue: ""),
            attribute("createdAt", .dateAttributeType, defaultValue: Date())
        ])

        let photo = entity("DestinationPhoto", class: DestinationPhoto.self, attributes: [
            attribute("identifier", .UUIDAttributeType, defaultValue: UUID()),
            attribute("imageData", .binaryDataAttributeType, defaultValue: Data(), externalStorage: true),
            attribute("createdAt", .dateAttributeType, defaultValue: Date())
        ])

        // MARK: Relations (avec inverses)

        relate(
            toMany: family, named: "babies", deleteRule: .nullifyDeleteRule,
            toOne: baby, named: "family", inverseDeleteRule: .nullifyDeleteRule
        )
        relate(
            toMany: family, named: "trips", deleteRule: .nullifyDeleteRule,
            toOne: trip, named: "family", inverseDeleteRule: .nullifyDeleteRule
        )
        relate(
            toMany: family, named: "destinations", deleteRule: .nullifyDeleteRule,
            toOne: destination, named: "family", inverseDeleteRule: .nullifyDeleteRule
        )
        relate(
            toMany: trip, named: "destinations", deleteRule: .cascadeDeleteRule,
            toOne: destination, named: "trip", inverseDeleteRule: .nullifyDeleteRule
        )
        relate(
            toMany: destination, named: "photos", deleteRule: .cascadeDeleteRule,
            toOne: photo, named: "destination", inverseDeleteRule: .nullifyDeleteRule
        )

        let model = NSManagedObjectModel()
        model.entities = [family, baby, trip, destination, photo]
        return model
    }

    // MARK: - Helpers

    private static func entity(
        _ name: String,
        class managedClass: NSManagedObject.Type,
        attributes: [NSAttributeDescription]
    ) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = NSStringFromClass(managedClass)
        entity.properties = attributes
        return entity
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil,
        externalStorage: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        attribute.allowsExternalBinaryDataStorage = externalStorage
        return attribute
    }

    /// Crée une paire de relations inverses : `owner.named` (to-many)
    /// ↔ `member.inverseNamed` (to-one). Toutes optionnelles (CloudKit).
    private static func relate(
        toMany owner: NSEntityDescription, named toManyName: String, deleteRule: NSDeleteRule,
        toOne member: NSEntityDescription, named toOneName: String, inverseDeleteRule: NSDeleteRule
    ) {
        let toMany = NSRelationshipDescription()
        toMany.name = toManyName
        toMany.destinationEntity = member
        toMany.minCount = 0
        toMany.maxCount = 0
        toMany.deleteRule = deleteRule
        toMany.isOptional = true

        let toOne = NSRelationshipDescription()
        toOne.name = toOneName
        toOne.destinationEntity = owner
        toOne.minCount = 0
        toOne.maxCount = 1
        toOne.deleteRule = inverseDeleteRule
        toOne.isOptional = true

        toMany.inverseRelationship = toOne
        toOne.inverseRelationship = toMany

        owner.properties.append(toMany)
        member.properties.append(toOne)
    }
}
