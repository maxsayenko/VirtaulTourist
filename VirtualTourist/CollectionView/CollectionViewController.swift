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
    
    private let leftAndRightPaddings: CGFloat = 5.0
    private let numberOfItemsPerRow: CGFloat = 3.0
    private let totalSectionsInsets: CGFloat = 6.0 // From storyboard
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var collection: UICollectionView!
    
    override func viewDidLoad() {
        let bounds = UIScreen.mainScreen().bounds
        let width = (bounds.size.width - totalSectionsInsets - leftAndRightPaddings * (numberOfItemsPerRow + 1)) / numberOfItemsPerRow
        let layout = collection.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSizeMake(width, width)
        debugPrint("width = \(width)")
        
        if let annotation = mapPinAnnotation {
            map.addAnnotation(annotation)
            let span = MKCoordinateSpanMake(0.075, 0.075)
            let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
            map.setRegion(region, animated: true)
            print(annotation.coordinate)
            
            // TODO: Network
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
        
        let photoInfo = collectionImages[indexPath.row]
        
        // TODO: Network
        Alamofire.request(.GET, photoInfo.getImageUrl(), parameters: nil, encoding: ParameterEncoding.URL, headers: ["Content-Type":"image"])
            .responseImage { response in
                if let image = response.result.value {
                    dispatch_async(dispatch_get_main_queue(), {
                        if let cellToUpdate = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell? {
                            cellToUpdate.picture.image = image
                            cellToUpdate.stopSpinner()
                        }
                    })
                }
        }

        return cell
    }
}
