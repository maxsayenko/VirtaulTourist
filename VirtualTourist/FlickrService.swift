//
//  FlickrService.swift
//  VirtualTourist
//
//  Created by Max Saienko on 7/27/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import MapKit
import Alamofire
import PromiseKit

struct FlickrService {
    static func GetImages(page: Int = 1, annotation: MKAnnotation) -> Promise<AnyObject> {
        return Promise { fulfill, reject in
            Alamofire.request(.GET, Config.API.Domain,
                            parameters: [
                                "method": Config.API.SearchMethod,
                                "api_key": Config.API.Key,
                                "lat": annotation.coordinate.latitude,
                                "lon": annotation.coordinate.longitude,
                                "format": Config.API.Format,
                                "per_page": 21,
                                "page": page,
                                "nojsoncallback": "1"
                            ])
                .validate()
                .responseJSON { response in
                    switch response.result {
                        case .Success(let result):
                            fulfill(result)
                        case .Failure(let error):
                            reject(error)
                    }
            }
        }

        
        
        
        // TODO: Network
//        Alamofire.request(.GET, Config.API.Domain,
//            parameters: [
//                "method": Config.API.SearchMethod,
//                "api_key": Config.API.Key,
//                "lat": annotation.coordinate.latitude,
//                "lon": annotation.coordinate.longitude,
//                "format": Config.API.Format,
//                "per_page": 21,
//                "page": page,
//                "nojsoncallback": "1"
//            ])
//            .validate().

//            .responseJSON { (response) -> Void in
//                debugPrint(response)
//                guard response.result.isSuccess else {
//                    print("Error while fetching photos data: \(response.result.error)")
//                    return
//                }
//                if let result = response.result.value {
//                    let jsonData = JSON(result)
//                    if let totalPages = jsonData["photos", "pages"].int {
//                        self.totalPagesForThisCollection = totalPages
//                    }
//                    
//                    if let photos = jsonData["photos","photo"].array {
//                        self.collectionImages = photos.map({ photoJson -> PhotoInfo? in
//                            return PhotoInfo(imageJsonData: photoJson)
//                        }).flatMap{ $0 }
//                        self.collection.reloadData()
//                    }
//                }
//        }
    }
}