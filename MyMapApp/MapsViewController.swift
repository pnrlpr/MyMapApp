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
    
    var secilenTitle = ""
    var secilenId : UUID?
    
    
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
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
        if secilenTitle != "" {
            //CoreData'dan verileri çek
            
            if let uuidString = secilenId?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                //Filtreleme
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    //Bu bize bir any tipinde dizi verir
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count>0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            
                            //İlk önce bütün if'leri ayrı ayrı birbirinden bağımsız yazmıştık. O şekilde kalırsa başlık, açıklama, enlem ve boylamdan herhangi biri ya da birkaçı eksik olsa da çalışır
                            //Fakat alttaki gibi iç içe if'ler şekinde yaparsak bütün parametrelerin olması zorunlu olur.
                            if let title = sonuc.value(forKey: "title") as? String {
                                annotationTitle = title
                                
                                if let subtitle = sonuc.value(forKey: "subtitle") as? String {
                                    annotationSubtitle = subtitle
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            //Annotation kodu (pin gösterme kodu) en içteki if'in içinde yazıldı
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            baslikTextField.text = annotationTitle
                                            aciklamaTextField.text = annotationSubtitle
                                            
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } catch {
                    print ("Hata")
                }
            }
            
        } else {
            //yeni veri eklenecek
        }
        
    }
    
    //Harita üzerinde navigasyon oluşturmak için / yol tarifi
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            //Pin'e tıklayınca yanda çıkan "i" butonu
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    
    //Pin'in yanındaki "i" butonuna tıklayınca yol tarifi almak:
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) {(placeMarkDizisi, hata) in
                
                
                //if let kullanarak placeMarkDizisi'ni opsiyonel olmaktan çıkarıyoruz. Bunu yapmayınca hata veriyor.
                if let placemarks = placeMarkDizisi {
                    if placemarks.count > 0 {
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        
                        //Buraya kadarki bütün işlemler aşağıdaki yeniPlaceMark'ı alabilmek içindi. :)
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        //Haritada nav ilk açıldığında araba ile seçeneği açılır
                        //Kullanıcı sonradan değiştirebilir
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
               
            }
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
        
        if secilenTitle == "" {
            //LOKASYON HER GÜNCELLENDİĞİNDE HARİTA GÖRÜNÜMÜNÜ GÜNCELLEME
            // lokasyon belirleme
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
            //Ekrandaki haritayı konuma göre değiştirme:
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
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
        
        //Veriler kaydedildikten sonraki işlemler:
        NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
        
        
        
    }
    
    
}

