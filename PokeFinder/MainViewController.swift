//
//  MainViewController.swift
//  PokeFinder
//
//  Created by Bailig Abhanar on 2017-04-11.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import MapKit
import GeoFire

class MainViewController: UIViewController {

    let locationManager = CLLocationManager()
    var mapCenteredOnce = false
    
    @IBOutlet weak var mapView: MKMapView!
    @IBAction func randomPokemonBtnPressed(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // track user location
        mapView.userTrackingMode = MKUserTrackingMode.follow
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // ask for location authorization after the view appear
        locationAuthStatus()
    }
    
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    

}

extension MainViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // center the map whenever GPS on the phone updates
        guard let userLocation = userLocation.location, !mapCenteredOnce else {
            print("error: new updated user location assignment failed!")
            return
        }
        centerMap(onLocation: userLocation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // change user annotation on the map to image ash
        var annotationView: MKAnnotationView?
        
        // if the annotation is a user location annotation, change annotation to ash
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "user")
            annotationView?.image = UIImage(named: "ash")
        }
        
        return annotationView
    }
    
    /// helpers
    func centerMap(onLocation location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(coordinateRegion, animated: true)
        mapCenteredOnce = true
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
}

