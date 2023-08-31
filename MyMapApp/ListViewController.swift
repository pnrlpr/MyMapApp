//
//  ListViewController.swift
//  MyMapApp
//
//  Created by PINAR KALKAN on 31.08.2023.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var titleDizisi = [String]()
    var idDizisi = [UUID]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(artiButonuTiklandı))
        
        veriAl()
    }
    
    func veriAl (){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        request.returnsObjectsAsFaults = false
        
        do{
            let sonuclar = try context.fetch(request)
            
            if sonuclar.count > 0 {
                
                titleDizisi.removeAll(keepingCapacity: false)
                idDizisi.removeAll(keepingCapacity: false)
                
                //dizideki verileri (DB'deki kayıtlı verileri) bize "Any" tipinde verir
                //Bizim NSManagedObject tipinde veriye ihtiyacımız var
                //Bu yüzden önce sonuçları NSManagedObject tipinde çeviriyoruz
                for sonuc in sonuclar as! [NSManagedObject] {
                    
                    //Burda çağırdığımız veriler de "Any" tipinde verir
                    //Bu veri tiplerini de istediğimiz tipe cast ediyoruz
                    //BU verileri aldıktan sonra bir diziye kaydetmen gerekir
                    //Bunun için en üstte isimDizisi gibi boş diziler oluştur!!
                    //Sonra alttaki fonk'ların içinde diziye ekle
                    //Burada for döngüsüne girmeden önce dizileri boşalt
                    if let isim = sonuc.value(forKey: "title") as? String {
                        titleDizisi.append(isim)
                    }
                    
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                }
                
                //İşlemler bitince tableView'ı yeni dizileri içerecek şekilde yeniden yüklemek gerekiyor.
                tableView.reloadData()
            }
            
            
        } catch {
            print("Hata")
        }
        
    }
    
    
    @objc func artiButonuTiklandı (){
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleDizisi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleDizisi[indexPath.row]
        return cell
    }
  
}
