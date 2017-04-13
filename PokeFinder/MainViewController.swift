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
import FirebaseDatabase

class MainViewController: UIViewController {

    let locationManager = CLLocationManager()
    var mapCenteredOnce = false
    var geoFire: GeoFire!
    // firebase database reference
    var firebaseDatabaseReference: FIRDatabaseReference!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBAction func randomPokemonBtnPressed(_ sender: Any) {
        let centerOfTheMap = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let randomNumber = arc4random_uniform(151) + 1
        createSighting(forLocation: centerOfTheMap, withPokemonId: Int(randomNumber))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // track user location
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        // firebase database reference
        firebaseDatabaseReference = FIRDatabase.database().reference()
        
        // geoFire
        geoFire = GeoFire(firebaseRef: firebaseDatabaseReference)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // ask for location authorization after the view appear
        locationAuthStatus()
    }
    
    /// helpers
    func locationAuthStatus() {
        // if authrized
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func createSighting(forLocation location: CLLocation, withPokemonId pokemonId: Int) {
        // geo fire sets the location information for the pokemon in firebase database
        geoFire.setLocation(location, forKey: "\(pokemonId)")
    }
    
    func showSightingsOnMap(withLocation location: CLLocation) {
        // use geo fire to query location passed in with radius in km
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        // any time we set a location for a key(id) the following closure will be called because we set the event type to key entered.
        // key entered events will be fired for all keys(id) initially matching the query as well as any time afterwards that a key enters the query.
        _ = circleQuery?.observe(GFEventType.keyEntered) { key, location in
            guard let key = key, let location = location else { return }
            // create pokemon annodations using the data returned by query
            let annotation = PokemonAnnotation(coordinate: location.coordinate, pokemonId: Int(key)!)
            // add the annotation to the map view
            self.mapView.addAnnotation(annotation)
        }
    }

}

// MARK: - MK Map View Delegate
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
        // this function will be called every time we add a annotation to a map view
        // configure all the annotations in this function
        
        var annotationView: MKAnnotationView?
        let pokemonAnnotationIdentifier = "pokemon"
        
        // if the annotation is the user location annotation, create the annotation view with user identifier, and change the image to ash
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "user")
            annotationView?.image = UIImage(named: "ash")
        } else { // if the annotation is not a user annotation
            // if can create a reusable annotation from the mapView with the pokemon identifier, set annotation to the reusable annotation
            if let reusableAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pokemonAnnotationIdentifier) {
                annotationView = reusableAnnotationView
                annotationView?.annotation = annotation
            } else { // if could not find the pokemon reusable annotation, create a empty one
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: pokemonAnnotationIdentifier)
                // set the view that displays on the right side of the standard callout bubble (popup window)
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            // setup the annotation for pokemon
            if let annotationView = annotationView, let annotation = annotation as? PokemonAnnotation {
                annotationView.canShowCallout = true
                annotationView.image = UIImage(named: "\(annotation.pokemonId)")
                let button = UIButton()
                button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                button.setImage(UIImage(named: "location-map-flat"), for: .normal)
                annotationView.rightCalloutAccessoryView = button
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // this function will be called when the region showing on the map is changed
        // update the map with the pokemons
        
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightingsOnMap(withLocation: location)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // this function will be called when the callout bubble (popup window) pressed
        // open the apple map with navigation information to the pressed pokemon
        guard let annotation = view.annotation as? PokemonAnnotation else { return }
        let place = MKPlacemark(coordinate: annotation.coordinate)
        let destination = MKMapItem(placemark: place)
        destination.name = "Pokemon Sighting"
        let regionDistance: CLLocationDistance = 1000
        let regionSpan = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionDistance, regionDistance)
        let options: [String : Any] = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span),
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        MKMapItem.openMaps(with: [destination], launchOptions: options)
    }
    
    /// helpers
    func centerMap(onLocation location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(coordinateRegion, animated: true)
        mapCenteredOnce = true
    }
}

// MARK: - CL Location Manager Delegate
extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
}

