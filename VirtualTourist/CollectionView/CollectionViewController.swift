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
import AlamofireImage
import SwiftyJSON

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var mapPinAnnotation:MKAnnotation?
    var collectionImages:[PhotoInfo] = []
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var collection: UICollectionView!
    
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
                    "per_page": 21,
                    "nojsoncallback": "1"
                ])
                .validate()
                .responseJSON { (response) -> Void in
                    guard response.result.isSuccess else {
                        print("Error while fetching photos data: \(response.result.error)")
                        return
                    }
                    if let result = response.result.value {
                        let jsonData = JSON(result)
                        if let photos = jsonData["photos","photo"].array {
                            self.collectionImages = photos.map({ photoJson -> PhotoInfo? in
                                return PhotoInfo(imageJsonData: photoJson)
                            }).flatMap{ $0 }
                            self.collection.reloadData()
                            print(self.collectionImages.count)
                        }
                    }
                }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath) as! PictureCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
//        cell.myLabel.text = self.items[indexPath.item]
        //cell.picture = UIImageView()
        let photoInfo = collectionImages[indexPath.row]
        debugPrint(photoInfo)
        debugPrint(photoInfo.getImageUrl())
        Alamofire.request(.GET, photoInfo.getImageUrl(), parameters: nil, encoding: ParameterEncoding.URL, headers: ["Content-Type":"image"])
            .responseImage { response in
                debugPrint(response)
//                
//                print(response.request)
//                print(response.response)
//                debugPrint(response.result)
//                
                if let image = response.result.value {
                    print("image downloaded: \(image)")
                    
//                    dispatch_async(dispatch_get_main_queue()) {
//                        cell.picture = UIImageView(image: image)
//                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        debugPrint("new pic at \(indexPath)")
                        if let cellToUpdate = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell? {
                            cellToUpdate.picture.image = image
                            //debugPrint(cellToUpdate.picture.image)
                        }
                    })
                }
        }
        
        cell.backgroundColor = UIColor.yellowColor() // make cell more visible in our example project
        
        return cell
    }
}
