//
//  Photo.swift
//  VirtualTourist
//
//  Created by Max Saienko on 7/8/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData

class Photo: NSManagedObject {
    @NSManaged var farmId: NSNumber?
    @NSManaged var id: String
    @NSManaged var serverId: String
    @NSManaged var secret: String
    @NSManaged var title: String
    @NSManaged var owner: String
    
    // Core Data - relational property
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init?(imageJsonData: JSON, context: NSManagedObjectContext) {
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        guard (imageJsonData.error == nil) else {
            return nil
        }
        
        if let farmId = imageJsonData["farm"].int {
            self.farmId = farmId
        }
        
        if let id = imageJsonData["id"].string {
            self.id = id
        }
        
        if let serverId = imageJsonData["server"].string {
            self.serverId = serverId
        }
        
        if let secret = imageJsonData["secret"].string {
            self.secret = secret
        }
        
        if let title = imageJsonData["title"].string {
            self.title = title
        }
        
        if let owner = imageJsonData["owner"].string {
            self.owner = owner
        }
    }
    
    func getImageUrl() -> String {
        return "https://farm\(farmId!).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
    }
}