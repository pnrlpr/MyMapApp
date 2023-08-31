//
//  ViewController.swift
//  MyMapApp
//
//  Created by PINAR KALKAN on 29.08.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var baslikTextField: UITextField!
    @IBOutlet weak var aciklamaTextField: UITextField!
    
    var secilenIsim = ""
    var secilenId : UUID?
    
    
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        //locationManager ayarları:
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        //Bu ayarlardan sonra info.plist'te lokasyon izni ayarlandı
        
        //Ekrandaki uzun basmayı algılamak için
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:)))
        //Kaç saniye basıldığında algılasın?
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
        
        //seçilen isim boş değil ise;
        if secilenIsim != "" {
            //CoreData'dan verileri çek
            
            
        } else {
            //yeni veri eklenecek
        }
        
    }
    
    //gestureRecognizer için objc func. Parametre olarak gestureRecognizer girdik çünkü gestureRecognizer'a viewDidLoad dışından, konumSec func içerisinden de ulaşabilmek istiyoruz.
    @objc func konumSec (gestureRecognizer : UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began {
            
            //DOKUNULAN YERİ KOORDİNATA ÇEVİRMEK:
            //dokunulan noktayı CGPoint olarak verir
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            //Üstte aldığımız CGPoint, parantez içinde ilk parametreye yazılır, ikincisi koordinatı nereden alacağın
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            //işaretleme işlemi:
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = baslikTextField.text
            annotation.subtitle = aciklamaTextField.text
            mapView.addAnnotation(annotation)
        }
        
    }
    
    

    //didupdate yazınca çıkıyor
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       // print(locations[0].coordinate.latitude)
       // print(locations[0].coordinate.longitude)
        
        
        //LOKASYON HER GÜNCELLENDİĞİNDE HARİTA GÖRÜNÜMÜNÜ GÜNCELLEME
        // lokasyon belirleme
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        //Ekrandaki haritayı konuma göre değiştirme:
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }

    @IBAction func kaydetButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniLokasyon = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context)
        
        yeniLokasyon.setValue(baslikTextField.text, forKey: "title")
        yeniLokasyon.setValue(aciklamaTextField.text, forKey: "subtitle")
        yeniLokasyon.setValue(secilenLatitude, forKey: "latitude")
        yeniLokasyon.setValue(secilenLongitude, forKey: "longitude")
        yeniLokasyon.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("Kayıt edildi")
        } catch {
            print("Hata var")
        }
        
    }
    
    
}

