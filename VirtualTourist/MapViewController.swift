//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Max Saienko on 6/18/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import MapKit
import UIKit

class MapViewController: UIViewController {
    @IBOutlet var map: MKMapView!
    
    override func viewDidLoad() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        map.addGestureRecognizer(longPressGesture)
        map.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationItem.title = "Virtual Tourist"
        for annotation in map.selectedAnnotations {
            map.deselectAnnotation(annotation, animated: false)
        }
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.Began) {
            let touchPoint = gestureRecognizer.locationInView(map)
            let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            map.addAnnotation(annotation)

            
//            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
//                if error != nil {
//                    print("Reverse geocoder failed with error" + error!.localizedDescription)
//                    return
//                }
//                
//                if(placemarks!.count > 0) {
//                    let pm = placemarks![0] 
//                    
//                    // not all places have thoroughfare & subThoroughfare so validate those values
//                    annotation.title = "\(pm.thoroughfare), \(pm.subThoroughfare)"
//                    annotation.subtitle = pm.subLocality
//                    //self.map.showAnnotations([annotation], animated: true)
//                    self.map.addAnnotation(annotation)
//                    print(pm)
//                }
//                else {
//                    annotation.title = "Unknown Place"
//                    self.map.addAnnotation(annotation)
//                    print("Problem with the data received from geocoder")
//                }
////                places.append(["name":annotation.title,"latitude":"\(newCoordinates.latitude)","longitude":"\(newCoordinates.longitude)"])
//            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "collectionSegue")
        {
            navigationItem.title = "OK"
            if let _ = segue.destinationViewController as? CollectionViewController {
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
        self.performSegueWithIdentifier("collectionSegue", sender: self)
    }
}

