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
import CoreData

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: - Core Data Convenience
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
//    // Step 1: This would be a nice place to paste the lazy fetchedResultsController
//    lazy var fetchedResultsController: NSFetchedResultsController = {
//        let fetchRequest = NSFetchRequest(entityName: "Movie")
//        
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
//        fetchRequest.predicate = NSPredicate(format: "actor == %@", self.actor)
//        
//        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
//        return fetchResultsController
//    }()
    
    
    
    var mapPinAnnotation:MKAnnotation?
    var collectionImages:[PhotoInfo] = []
    var picsToDelete:Set<NSIndexPath> = Set<NSIndexPath>()
    var currentPageIndex = 1
    var totalPagesForThisCollection: Int = 0
    
    private let leftAndRightPaddings: CGFloat = 5.0
    private let numberOfItemsPerRow: CGFloat = 3.0
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var collection: UICollectionView!

    @IBOutlet var newCollectionBtn: UIButton!
    @IBOutlet var deleteBtn: UIButton!

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
    
    @IBAction func deleteTouch(sender: UIButton) {
        for (indexPath) in picsToDelete.sort({ $0.row > $1.row }) {
            collectionImages.removeAtIndex(indexPath.row)
        }
        collection.deleteItemsAtIndexPaths(Array(picsToDelete))
        picsToDelete.removeAll()
        
        updateButtonsVisibility()
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
    
    func updateButtonsVisibility() {
        if(picsToDelete.count > 0) {
            newCollectionBtn.hidden = true
            deleteBtn.hidden = false
        } else {
            newCollectionBtn.hidden = false
            deleteBtn.hidden = true
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
        
        cell.unSelect()
        if(picsToDelete.contains(indexPath)) {
            cell.select()
        }

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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell
        
        if(picsToDelete.contains(indexPath)) {
            cell.unSelect()
            picsToDelete.remove(indexPath)
        } else {
            cell.select()
            picsToDelete.insert(indexPath)
        }
        
        updateButtonsVisibility()
    }
    
    
}
