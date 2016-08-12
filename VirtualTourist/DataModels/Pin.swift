//
//  Pin.swift
//  VirtualTourist
//
//  Created by Max Saienko on 8/6/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject {
    @NSManaged var lat: String
    @NSManaged var long: String
    // Core Data - relational property
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude lat: String, longtitude long: String, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context!)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.lat = lat
        self.long = long
    }
    
    init(coordinates: CLLocationCoordinate2D, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context!)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.lat = String(coordinates.latitude)
        self.long = String(coordinates.longitude)
    }
    
    var annotation: MKAnnotation {
        let coordinates = CLLocationCoordinate2D(latitude: Double(self.lat)!, longitude: Double(self.long)!)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        return annotation
    }
}
