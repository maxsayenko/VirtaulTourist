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
    var currentPageIndex = 1
    var totalPagesForThisCollection: Int = 0
    
    private let leftAndRightPaddings: CGFloat = 5.0
    private let numberOfItemsPerRow: CGFloat = 3.0
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var collection: UICollectionView!
    @IBAction func newCollectionTouch(sender: UIButton) {
        self.collectionImages = []
        self.collection.reloadData()
        
        if let annotation = mapPinAnnotation {
            map.addAnnotation(annotation)
            let span = MKCoordinateSpanMake(0.075, 0.075)
            let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
            map.setRegion(region, animated: true)
            print(annotation.coordinate)
            
            FlickrService.GetImages(++currentPageIndex, annotation: annotation).then { result -> Void in
                self.collectionImages = result.photoInfos
                self.collection.reloadData()
            }.error { error in
                debugPrint("Error while fetching photos data: \(error)")
                debugPrint(error)
            }
        }
    }
    
    override func viewDidLoad() {
        let layout = collection.collectionViewLayout as! UICollectionViewFlowLayout
        let totalSectionsInsets = layout.sectionInset.left + layout.sectionInset.right
        let bounds = UIScreen.mainScreen().bounds
        let width = (bounds.size.width - totalSectionsInsets - leftAndRightPaddings * (numberOfItemsPerRow + 1)) / numberOfItemsPerRow
        layout.itemSize = CGSizeMake(width, width)
        
        if let annotation = mapPinAnnotation {
            map.addAnnotation(annotation)
            let span = MKCoordinateSpanMake(0.075, 0.075)
            let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
            map.setRegion(region, animated: true)
            
            FlickrService.GetImages(annotation: annotation).then { result -> Void in
                self.totalPagesForThisCollection = result.pagesCount
                self.collectionImages = result.photoInfos
                self.collection.reloadData()
            }.error { error in
                debugPrint("Error while fetching photos data: \(error)")
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath) as! PictureCell
        cell.picture?.image = nil
        cell.startSpinner()
        let photoInfo = collectionImages[indexPath.row]
        
        Service.LoadImage(url: photoInfo.getImageUrl()).then { image in
            dispatch_async(dispatch_get_main_queue(), {
                if let cellToUpdate = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell? {
                    cellToUpdate.picture!.image = image
                    cellToUpdate.stopSpinner()
                }
            })
        }.error{ err in
            debugPrint("Error while fetching Image from url: \(err)")
        }

        return cell
    }
}
