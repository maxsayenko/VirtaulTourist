//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Max Saienko on 6/18/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class MapViewController: UIViewController {
    // Core Data - Convenience methods
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }

    var pins = [Pin]()
    
    @IBOutlet var map: MKMapView!
    
    override func viewDidLoad() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        map.addGestureRecognizer(longPressGesture)
        map.delegate = self
        
        // CoreData - fetching pins
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            pins = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            debugPrint("MapView Fetch failed: \(error.localizedDescription)")
        }
        
        map.addAnnotations(pins.map({$0.annotation}))
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationItem.title = "Virtual Tourist"
        for annotation in map.selectedAnnotations {
            map.deselectAnnotation(annotation, animated: false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationItem.title = "OK"
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.Began) {
            let touchPoint = gestureRecognizer.locationInView(map)
            let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
            // CoreData - Saving new pin
            let pin = Pin(coordinates: newCoordinates, insertIntoManagedObjectContext: sharedContext)
            saveContext()
            map.addAnnotation(pin.annotation)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "collectionSegue")
        {
            let annotation = sender as! MKAnnotation
            if let ctrl = segue.destinationViewController as? CollectionViewController {
                // CoreData - fetching pin that was touched
                let query = "lat = \(annotation.coordinate.latitude) AND long = \(annotation.coordinate.longitude)"
                let fetchRequest = NSFetchRequest(entityName: "Pin")
                fetchRequest.predicate = NSPredicate(format: query)
                do {
                    let clickedPins = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
                    if(clickedPins.count != 1) {
                        debugPrint("MapView-Segue Wrong count of clicker Pins")
                    }
                    // Assigning a pin from CoreData to the next ctrl
                    ctrl.pin = clickedPins[0]
                } catch let error as NSError {
                    debugPrint("MapView-Segue Fetch failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    // Called when the annotation was added
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if (pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesDrop = true
            pinView?.canShowCallout = false
            pinView?.draggable = false
            pinView?.pinTintColor = UIColor.purpleColor()
            
            let rightButton: AnyObject! = UIButton(type: UIButtonType.DetailDisclosure)
            pinView?.rightCalloutAccessoryView = rightButton as? UIView
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    //Selecting annotation
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        performSegueWithIdentifier("collectionSegue", sender: view.annotation)
    }
}

