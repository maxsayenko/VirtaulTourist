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
    var picsToDelete:Set<NSIndexPath> = Set<NSIndexPath>()
    var currentPageIndex = 1
    var totalPagesForThisCollection: Int?
    
    var blockOperations: [NSBlockOperation] = []
    
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
    
    override func viewDidLoad() {
        // UI logic
        self.messageLbl.hidden = true
        self.newCollectionBtn.enabled = true

        let layout = collection.collectionViewLayout as! UICollectionViewFlowLayout
        let totalSectionsInsets = layout.sectionInset.left + layout.sectionInset.right
        let bounds = UIScreen.mainScreen().bounds
        let width = (bounds.size.width - totalSectionsInsets - leftAndRightPaddings * (numberOfItemsPerRow + 1)) / numberOfItemsPerRow
        layout.itemSize = CGSizeMake(width, width)
        
        if let pin = pin {
            
            // Dropping pin on a small map
            map.addAnnotation(pin.annotation)
            let span = MKCoordinateSpanMake(0.075, 0.075)
            let region = MKCoordinateRegion(center: pin.annotation.coordinate, span: span)
            map.setRegion(region, animated: true)
            
            // CoreData - Perform the FETCH and assign fetchedResultsController's delegate
            do {
                try fetchedResultsController.performFetch()
            } catch let err as NSError {
                print("fetchedResultsController.performFetch ERROR = \(err.localizedDescription)")
            }
            
            fetchedResultsController.delegate = self
            
            if(pin.photos.count == 0) {
                debugPrint("No images associated with this Pin. Will download and assign")
                FlickrService.GetImages(pin.annotation).then { result -> Void in
                    self.receiveNewImages(result.pagesCount, photoInfos: result.photoInfos)
                    }.error { error in
                        debugPrint("Error while fetching photos data: \(error)")
                }
            }
        }
    }
    
    @IBAction func newCollectionTouch(sender: UIButton) {
        debugPrint("New Collection. Current page = \(currentPageIndex)")
        if let pagesCount = totalPagesForThisCollection {
            guard currentPageIndex < pagesCount else {
                debugPrint("No more pages. Total Pages count = \(totalPagesForThisCollection). Current page = \(currentPageIndex)")
                return
            }
        }
        
        if let pin = pin {
            FlickrService.GetImages(pin.annotation, page: ++currentPageIndex).then { result -> Void in
                debugPrint("Deleting \(self.fetchedResultsController.fetchedObjects?.count) objects")
                for (photoObj) in (self.fetchedResultsController.fetchedObjects)! {
                    self.sharedContext.deleteObject(photoObj as! NSManagedObject)
                }
                
                self.receiveNewImages(result.pagesCount, photoInfos: result.photoInfos)
                }.error { error in
                    debugPrint("Error while fetching new collection photos data: \(error)")
            }
        }
    }
    
    @IBAction func deleteTouch(sender: UIButton) {
        for (indexPath) in picsToDelete.sort({ $0.row > $1.row }) {
            let item = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
            sharedContext.deleteObject(item)
        }
        picsToDelete.removeAll()
        updateButtonsVisibility()
        // CoreData - saving the deleted images. Also it will allow us to clean up the all pins once new collection is requested
        saveContext()
    }
    
    func receiveNewImages(pagesCount: Int, photoInfos: [Photo]) {
        self.totalPagesForThisCollection = pagesCount
        debugPrint("total pages = \(self.totalPagesForThisCollection)")
        
        // Handling 0 or 1 page OR when on the last page
        if (self.totalPagesForThisCollection < 2) || (self.totalPagesForThisCollection == currentPageIndex) {
            self.newCollectionBtn.enabled = false
        }
        
        // Handling 0 images scenario
        if (photoInfos.isEmpty) {
            self.messageLbl.hidden = false
        }
                
        pin?.photos = NSOrderedSet(array: photoInfos)
        
        // CoreData - Save the context
        self.saveContext()
        
        // Update the collection on the main thread
        dispatch_async(dispatch_get_main_queue()) {
            self.collection.reloadData()
        }
    }
    

    
    override func viewWillDisappear(animated: Bool) {
        saveContext()
        super.viewWillDisappear(animated)
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
    
    deinit {
        // Cancel all block operations when VC deallocates
        for operation: NSBlockOperation in blockOperations {
            operation.cancel()
        }
        
        blockOperations.removeAll(keepCapacity: false)
    }
}



// MARK: CollectionView
extension CollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // CoreData - making sure we have a Photo Item
        if let photoInfo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
            // get a reference to our storyboard cell
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath) as! PictureCell
            
            cell.unSelect()
            if(picsToDelete.contains(indexPath)) {
                cell.select()
            }
            
            // CoreData - checking if image was present in DB
            if let imageData = photoInfo.image {
                cell.picture?.image = UIImage(data:imageData)
            } else {
                cell.picture?.image = nil
                cell.startSpinner()
                
                Service.LoadImage(url: photoInfo.getImageUrl()).then { image in
                    dispatch_async(dispatch_get_main_queue(), {
                        if let imageData = UIImagePNGRepresentation(image) {
                            photoInfo.image = imageData
                        }
                        if let cellToUpdate = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell? {
                            cellToUpdate.picture!.image = image
                            cellToUpdate.stopSpinner()
                        }
                    })
                    }.error{ err in
                        debugPrint("Error while fetching Image from url: \(err)")
                }
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
        blockOperations.removeAll(keepCapacity: false)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if(collection.window == nil) {
            return
        }
        
        switch type {
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    self!.collection!.insertItemsAtIndexPaths([newIndexPath!])
                    })
            )
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    self!.collection.deleteItemsAtIndexPaths([indexPath!])
                    })
            )
        case .Move:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    self!.collection.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    })
            )
        case .Update:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    self!.collection.reloadItemsAtIndexPaths([indexPath!])
                    })
            )
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if (collection.window == nil) {
            return;
        }
        
        collection!.performBatchUpdates({ () -> Void in
            for operation: NSBlockOperation in self.blockOperations {
                operation.start()
            }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepCapacity: false)
        })
    }
}
