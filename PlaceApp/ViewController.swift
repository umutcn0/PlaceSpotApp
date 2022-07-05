//
//  ViewController.swift
//  PlaceApp
//
//  Created by Umut Can on 15.06.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIApplicationDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    var locationManager = CLLocationManager()
    var latitude : Double?
    var longitude : Double?
    var selectedName = ""
    var selectedID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        locationManager.delegate = self
        mapView.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapPressed))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        // Burada mapView'de 3 saniye tıklama süresi ile aksiyon alması sağlanıcak
        
        if selectedName != ""{
            saveButton.isHidden = true
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedID?.uuidString
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            
            do{
                let results = try context.fetch(fetchRequest)
                
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "name") as? String,
                       let comment = result.value(forKey: "comment") as? String,
                       let selectedlatitude = result.value(forKey: "latitude") as? Double,
                       let selectedlongitude  = result.value(forKey: "longitude") as? Double{
                        annotationTitle = name
                        annotationSubtitle = comment
                        annotationLatitude = selectedlatitude
                        annotationLongitude = selectedlongitude
                        
                        let annotation = MKPointAnnotation()
                        annotation.title = annotationTitle
                        annotation.subtitle = annotationSubtitle
                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                        annotation.coordinate = coordinate
                        
                        mapView.addAnnotation(annotation)
                        nameField.text = name
                        commentField.text = comment
                        
                        locationManager.stopUpdatingLocation()
                        
                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        let region = MKCoordinateRegion(center: coordinate, span: span)
                        mapView.setRegion(region, animated: true)
                        
                        
                    }
                }
            }catch{
                print("Error")
            }
            
        }
    }
    
    @objc func mapPressed(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            latitude = touchedCoordinates.latitude
            longitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameField.text
            annotation.subtitle = commentField.text
            self.mapView.addAnnotation(annotation)
        }
        
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        
        
        return pinView
    }
        
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            latitude = locations[0].coordinate.latitude
            longitude = locations[0].coordinate.longitude
            mapView.setRegion(region, animated: true)
        }
    }

    @IBAction func saveClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        if let latitude = latitude {
            object.setValue(latitude, forKey: "latitude")
        }
        if let longitude = longitude {
            object.setValue(longitude, forKey: "longitude")
        }
        object.setValue(nameField.text, forKey: "name")
        object.setValue(commentField.text, forKey: "comment")
        object.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("Success")
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("itemSaved"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                                      
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                                      
                    }
                }
            }
        }
    }
}
