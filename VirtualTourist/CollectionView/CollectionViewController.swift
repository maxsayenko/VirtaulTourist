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

class CollectionViewController: UIViewController {
    var pin:Pin?
    var collectionImages:[Photo] = []
    var picsToDelete:Set<NSIndexPath> = Set<NSIndexPath>()
    var currentPageIndex = 1
    var totalPagesForThisCollection: Int = 0
    
    private let leftAndRightPaddings: CGFloat = 5.0
    private let numberOfItemsPerRow: CGFloat = 3.0
    
    // CoreData - Convenience methods
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var collection: UICollectionView!
    
    @IBOutlet var messageLbl: UILabel!

    @IBOutlet var newCollectionBtn: UIButton!
    @IBOutlet var deleteBtn: UIButton!

    @IBAction func newCollectionTouch(sender: UIButton) {
        self.collectionImages = []
        self.collection.reloadData()
        
        if let pin = pin {
            map.addAnnotation(pin.annotation)
            let span = MKCoordinateSpanMake(0.075, 0.075)
            let region = MKCoordinateRegion(center: pin.annotation.coordinate, span: span)
            map.setRegion(region, animated: true)
            print(pin.annotation.coordinate)
            
            FlickrService.GetImages(pin.annotation, page: ++currentPageIndex).then { result -> Void in
                self.collectionImages = result.photoInfos
                self.collection.reloadData()
            }.error { error in
                debugPrint("Error while fetching photos data: \(error)")
                debugPrint(error)
            }
        }
    }
    
    @IBAction func deleteTouch(sender: UIButton) {
//        for (indexPath) in picsToDelete.sort({ $0.row > $1.row }) {
//            collectionImages.removeAtIndex(indexPath.row)
//        }
//        collection.deleteItemsAtIndexPaths(Array(picsToDelete))
//        picsToDelete.removeAll()
//        
//        updateButtonsVisibility()
    }
    
    override func viewDidLoad() {
        debugPrint("View did load")
        self.messageLbl.hidden = true
        self.newCollectionBtn.enabled = true
        
        let layout = collection.collectionViewLayout as! UICollectionViewFlowLayout
        let totalSectionsInsets = layout.sectionInset.left + layout.sectionInset.right
        let bounds = UIScreen.mainScreen().bounds
        let width = (bounds.size.width - totalSectionsInsets - leftAndRightPaddings * (numberOfItemsPerRow + 1)) / numberOfItemsPerRow
        layout.itemSize = CGSizeMake(width, width)
        
        
        
        // CoreData - Perform the FETCH and assign fetchedResultsController's delegate
        do {
            try fetchedResultsController.performFetch()
        } catch let err as NSError {
            print("fetchedResultsController.performFetch ERROR = \(err.localizedDescription)")
        }
        
        fetchedResultsController.delegate = self
        debugPrint("fetched objects count = \(fetchedResultsController.fetchedObjects?.count)")
        
        
        

        if let pin = pin {
            map.addAnnotation(pin.annotation)
            let span = MKCoordinateSpanMake(0.075, 0.075)
            let region = MKCoordinateRegion(center: pin.annotation.coordinate, span: span)
            map.setRegion(region, animated: true)
            print(pin.annotation.coordinate)
            
            if(pin.photos.isEmpty) {
                debugPrint("No images associated with this Pin. Will download and assign")
                FlickrService.GetImages(pin.annotation).then { result -> Void in
                    self.totalPagesForThisCollection = result.pagesCount
                    debugPrint("total pages = \(self.totalPagesForThisCollection)")
                    
                    // Handling 0 or 1 page
                    if (self.totalPagesForThisCollection < 2) {
                        self.newCollectionBtn.enabled = false
                    }

                    // Handling 0 images scenario
                    if (result.photoInfos.isEmpty) {
                        self.messageLbl.hidden = false
                    }
                    
                    //self.collectionImages = result.photoInfos
                    
                    for photoInfo in result.photoInfos {
                        photoInfo.pin = pin
                    }
                    
                    //pin.photos = result.photoInfos
                    //self.pin?.photos = NSSet(array: result.photoInfos)
                    
                    // CoreData - Save the context
                    self.saveContext()
                    
                    // Update the collection on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collection.reloadData()
                    }
                    
                    }.error { error in
                        debugPrint("Error while fetching photos data: \(error)")
                }
            } else {
//                collectionImages = pin.photos
//                self.collection.reloadData()
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
}




// MARK: CollectionView
extension CollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        debugPrint("number of sections = \(fetchedResultsController.sections?.count)")
        debugPrint("number of objects = \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects ?? 0
        //return collectionImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // CoreData - making sure we have a Photo Item
        if let photoInfo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
            // get a reference to our storyboard cell
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath) as! PictureCell
            cell.picture?.image = nil
            cell.startSpinner()
            
            cell.unSelect()
            if(picsToDelete.contains(indexPath)) {
                cell.select()
            }
            
            //let photoInfo = collectionImages[indexPath.row]
            
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
        
        return UICollectionViewCell()
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





// MARK: FetchedResultsController
extension CollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("MovieListViewController - controllerWillChangeContent")
        //tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        //print("MovieListViewController - didChangeSection \(type)")
        switch type {
        case .Insert: break
            //tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            
        case .Delete: break
            //tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        //print("MovieListViewController - didChangeObject \(type.rawValue)")
        switch type {
        case .Insert: break
            //tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete: break
            //tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Move: break
            //tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            //tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Update: break
//            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! ActorTableViewCell
//            let movie = self.fetchedResultsController.objectAtIndexPath(indexPath!) as! Movie
//            configureCell(cell, movie: movie)
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("MovieListViewController - controllerDidChangeContent")
        //tableView.endUpdates()
    }
}
