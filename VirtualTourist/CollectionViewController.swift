//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Max Saienko on 6/18/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import UIKit
import MapKit
import Alamofire

class CollectionViewController: UIViewController {
    var mapPinAnnotation:MKAnnotation?
    
    @IBOutlet var map: MKMapView!
    
    override func viewDidLoad() {
        if let annotation = mapPinAnnotation {
            map.addAnnotation(annotation)
            let span = MKCoordinateSpanMake(0.075, 0.075)
            let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
            map.setRegion(region, animated: true)
            print(annotation.coordinate)
            
            Alamofire.request(.GET, Config.API.Domain,
                parameters: [
                    "method": Config.API.SearchMethod,
                    "api_key": Config.API.Key,
                    "lat": annotation.coordinate.latitude,
                    "lon": annotation.coordinate.longitude,
                    "format": Config.API.Format,
                    "nojsoncallback": "1"
                ])
                .validate()
                .responseJSON { (response) -> Void in
                    guard response.result.isSuccess else {
                        print("Error while fetching photos data: \(response.result.error)")
                        return
                    }
                    
                    print(response)
                }
        }
    }
}
