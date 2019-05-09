//
//  ViewController.swift
//  Turn by Turn
//
//  Created by GUIEEN on 5/9/19.
//  Copyright © 2019 GUIEEN. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var directionsLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D!
    
    var steps = [MKRoute.Step]()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var stepCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
//        locationManager.requestState(for: <#T##CLRegion#>)
        locationManager.startUpdatingLocation()
        
         /* Setup delegates */
        searchBar.delegate = self // This is needed or searchBarDelegate will not work.
        mapView.delegate = self
        
    }
    
    func getDirections(to destination: MKMapItem) {
        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destination
        directionRequest.transportType = .automobile // car
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, _) in
            guard let response = response else { return }
            guard let primaryRoute = response.routes.first else { return }
            
            // polyline: the blue line when navi is started
            // Eventhough polyline is added to mapview's overlay, map will not draw this polyline -> need to render it
            self.mapView.addOverlay(primaryRoute.polyline)
            
            self.locationManager.monitoredRegions.forEach({
                print("**********")
                print($0)
                self.locationManager.stopMonitoring(for: $0)
            })
            
            self.steps = primaryRoute.steps // turn right, turn left
            
            // keyword: geo fences
            for i in 0 ..< primaryRoute.steps.count {
                let step = primaryRoute.steps[i]
                print(step.instructions)
                print(step.distance)
                
                let region = CLCircularRegion(center: step.polyline.coordinate, radius: 10, identifier: "\(i)")
                if (i != 0) {
                    self.locationManager.startMonitoring(for: region) // monitoring should be stopped on the above before excuting
                    
                }
                
                // post to this on map
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapView.addOverlay(circle)
            }
            
            let initialMessage = "In \(self.steps[0].distance) meters, \(self.steps[0].instructions) then in \(self.steps[1].distance) meters, \(self.steps[1].instructions)."
            self.directionsLabel.text = initialMessage
            
            // start speech implementation
            let speechUtterance = AVSpeechUtterance(string: initialMessage)
            self.speechSynthesizer.speak(speechUtterance)
            self.stepCounter += 1
        }
        
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        guard let currentLocation = locations.first else { return }
        currentCoordinate = currentLocation.coordinate
        
        print("currentLocation")
        print(currentLocation)
        
        mapView.userTrackingMode = .followWithHeading // always heading north when device is moving.
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("ENTERED")
        stepCounter += 1
        
        if stepCounter < steps.count {
            let currentStep = steps[stepCounter]
            let message = "In \(currentStep.distance) meters, \(currentStep.instructions)"
            directionsLabel.text = message
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
        } else {
            let message = "Arrived at destination"
            self.directionsLabel.text = message
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
            stepCounter = 0
            locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("---------------1111-------------------")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("---------------2222-------------------")
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("----------------3333------------------")
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        print("--------------4444--------------------")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("------------5555----------------------")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("---------------666666-------------------")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("------------------777777----------------")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("----------------8888------------------")
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        print("-----------------9999-----------------")
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("---------------10101010-------------------")
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        print("---------------a1a1-------------------")
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("-------------a2a2a2---------------------")
    }
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("---------------a3a3a3-------------------")
    }
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print("-----------------a4a4a4-----------------")
    }
    
    
}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)

        let localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = searchBar.text // search by natural language. ex) tokyo tower...

        print("----------------------------------------------")
        print(searchBar.text ?? "default Val")
        print("-------------------------------------------------------")

        // MKCoordinateSpan : values in this structure to indicate the desired zoom level of the map,
        let region = MKCoordinateRegion(center: currentCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))

        localSearchRequest.region = region
        let localSearch = MKLocalSearch(request: localSearchRequest)

        localSearch.start { (response, _) in
            guard let response = response else { return }
//            print(response.mapItems)
//            [...<MKMapItem: 0x6000026c98c0> {
//                isCurrentLocation = 0;
//                name = "Yanaka Coffee Chabara";
//                phoneNumber = "\U202d+81 120 511 720\U202c";
//                placemark = "Yanaka Coffee Chabara, 8-2, Kandaneribeicho, Chiyoda-Ku, Tokyo, Japan 101-0022 @ <+35.70039810,+139.77333130> +/- 0.00m, region CLCircularRegion (identifier:'<+35.70039811,+139.77333130> radius 141.17', center:<+35.70039811,+139.77333130>, radius:141.17m)";
//                timeZone = "Asia/Tokyo (GMT+9) offset 32400";
//                url = "http://www.yanaka-coffeeten.com";
//            }]
            
            guard let firstMapItem = response.mapItems.first else { return }

            self.getDirections(to: firstMapItem)
        }

    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            
            renderer.strokeColor = .blue
            renderer.lineWidth = 10
            
            return renderer
        }
        
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.fillColor = .yellow
            renderer.alpha = 0.5
            
            return renderer
        }
        
        return MKOverlayRenderer()
    }
}

