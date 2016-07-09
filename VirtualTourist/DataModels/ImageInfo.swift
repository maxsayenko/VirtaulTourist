//
//  ImageInfo.swift
//  VirtualTourist
//
//  Created by Max Saienko on 7/8/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import Foundation
import SwiftyJSON

struct ImageInfo {
    var farmId: Int?
    var id: String = ""
    var serverId: String = ""
    var secret: String = ""
    var title: String = ""
    var owner: String = ""
    
    init?(imageJsonData: JSON) {
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