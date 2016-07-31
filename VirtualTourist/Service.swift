//
//  Service.swift
//  VirtualTourist
//
//  Created by Max Saienko on 7/30/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import AlamofireImage
import SwiftyJSON
import PromiseKit

struct Service {
    static func LoadImage(url imageUrl: String) -> Promise<UIImage> {
        return Promise { fulfill, reject in
            Alamofire.request(.GET, imageUrl, parameters: nil, encoding: ParameterEncoding.URL, headers: ["Content-Type":"image"])
                .responseImage { response in
                    switch response.result {
                        case .Success(let image):
                            fulfill(image)
                        case .Failure(let error):
                            reject(error)
                    }
            }
        }
    }
}
