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
    @NSManaged var lat: NSNumber
    @NSManaged var long: NSNumber
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude lat: Double, longtitude long: Double, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context!)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.lat = NSNumber(double: lat)
        self.long = NSNumber(double: long)
    }
    
    init(coordinates: CLLocationCoordinate2D, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context!)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.lat = NSNumber(double: coordinates.latitude)
        self.long = NSNumber(double: coordinates.longitude)
    }
    
    var annotation: MKAnnotation {
        let coordinates = CLLocationCoordinate2D(latitude: Double(self.lat), longitude: Double(self.long))
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        return annotation
    }
}
