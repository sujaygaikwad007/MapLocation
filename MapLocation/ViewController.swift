import UIKit
import MapKit
import CoreLocation
import UPCarouselFlowLayout
import Alamofire
import AlamofireImage
import AdvancedPageControl

class ViewController: UIViewController, CLLocationManagerDelegate,UITextFieldDelegate,MKLocalSearchCompleterDelegate{
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var searchResultsTable:UITableView!
    @IBOutlet weak var GoBtnVar: UIButton!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var destinationSearch: UITextField!
    @IBOutlet weak var LblShowDistance: UILabel!
    @IBOutlet weak var ZoomBtnStack: UIStackView!
    
    @IBOutlet weak var collectionViewObj: UICollectionView!
    
    @IBOutlet weak var PageControl: AdvancedPageControlView!
    
    
    
    let manager = CLLocationManager()
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    var sourceActive = false
    var mKPointAnnotation = [MKPointAnnotation]()
    var pulseLayer: CAShapeLayer?
    var isValid = false
    var base_url = "https://restcountries.com/v3.1/all"
    
    
    var apiItems: [APIData] = []
    
    //Add carousel for Colection View-----Start
    fileprivate var pageSize: CGSize {
        let layout = self.collectionViewObj.collectionViewLayout as! UPCarouselFlowLayout
        var pageSize = layout.itemSize
        if layout.scrollDirection == .horizontal {
            pageSize.width += layout.minimumLineSpacing
        } else {
            pageSize.height += layout.minimumLineSpacing
        }
        return pageSize
    }
    
    fileprivate var orientation: UIDeviceOrientation {
        return UIDevice.current.orientation
    }
    //Add carousel for Colection View-----End
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        searchResultsTable.isHidden = true
        LblShowDistance.isHidden = true
        searchBar.delegate = self
        destinationSearch.delegate = self
        searchCompleter.delegate = self
        searchResultsTable?.delegate = self
        searchResultsTable?.dataSource = self
        mapView.delegate = self
        
        collectionViewObj.delegate = self
        collectionViewObj.dataSource = self
        
        let nibName = UINib(nibName: "CountriesCollectionViewCell", bundle: nil)
        self.collectionViewObj.register(nibName, forCellWithReuseIdentifier: "CountriesCollectionViewCell")
        
        setupLayout()
        APIDataPass()
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
    }
    
    //Set layout for carousel-----Start
    fileprivate func setupLayout() {
        let layout = self.collectionViewObj.collectionViewLayout as! UPCarouselFlowLayout
        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.overlap(visibleOffset: 30)
        layout.itemSize = CGSize(width: 300, height: 300)
        
    }
    //Set layout for carousel-----End
    
    
    //Code for current location-----Start
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            manager.stopUpdatingLocation()
            render(location)
        }
    }
    
    func render(_ location: CLLocation){
        
        print("From Current Location--------")
        
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude,longitude: location.coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        let region = MKCoordinateRegion(center: coordinate,span: span)
        mapView.setRegion(region,animated: true)
        
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        pin.title="Current Location"
        mapView.addAnnotation(pin)
        self.mKPointAnnotation.append(pin)
    }
    
    //Code for current location-----End
    
    
    
    //Display table with results of suggest location --- Start
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("textFieldShouldBeginEditing")
        if textField == searchBar {
            if self.mKPointAnnotation.count > 0 {
                self.mapView.removeAnnotations(self.mKPointAnnotation)
            }
        }
        
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard !textField.text!.isEmpty else {return}
        self.sourceActive = textField == searchBar
        if textField == destinationSearch || textField == searchBar{
            ZoomBtnStack.isHidden = true
            searchResultsTable.isHidden = false
            searchCompleter.queryFragment = textField.text ?? ""
        }
        
    }
    //Display table with results of suggest location --- End
    
    //Reload results in tables
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchResultsTable.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Eroor Message--------")
    }
    
    ///Zoom in and Zoom out button ------- Start
    @IBAction func zoomInBtnTapped(_ sender: UIButton) {
        print("Zoom In button-------")
        zoomMapView(byfactor: 0.5)
    }
    
    @IBAction func zoomOutBtnTapped(_ sender: UIButton) {
        print("Zoom out button-------")
        zoomMapView(byfactor: 2.0)
    }
    ///Zoom in and Zoom out button ------- End
    
    @IBAction func GoBtnClicked(_ sender: UIButton) {
        
        if searchBar.text!.isEmpty && destinationSearch.text!.isEmpty{
            showToast(controller: self, message: "Please Enter place", seconds: 2)
            
        }
        else{
            print("Button Clicked----------")
            DistnceCal()
            LblShowDistance.isHidden = false
            
            if self.mKPointAnnotation.count > 2 {
                self.mapView.removeOverlays(self.mapView.overlays)
            }
            
            removeRippleAnimation()
            
        }
    }
    
    
    //Calculate distance between two places-----Start
    func DistnceCal() {
        
        print("Call distnce calculator Function---------")
        
        guard let firstSearchBarText = searchBar.text, !firstSearchBarText.isEmpty,
              let secondSearchBarText = destinationSearch.text, !secondSearchBarText.isEmpty else {
                  return
              }
        
        let firstGeocoder = CLGeocoder()
        firstGeocoder.geocodeAddressString(firstSearchBarText) { (firstPlacemarks, firstError) in
            guard let firstLocation = firstPlacemarks?.first?.location else {
                return
            }
            
            let secondGeocoder = CLGeocoder()
            secondGeocoder.geocodeAddressString(secondSearchBarText) { (secondPlacemarks, secondError) in
                guard let secondLocation = secondPlacemarks?.first?.location else {
                    return
                }
                
                print("First Location-------------\(firstLocation)")
                
                let distance = firstLocation.distance(from: secondLocation)
                let distanceInKm = Int(distance / 1000)
                let distanceInMeter = Int(distance.truncatingRemainder(dividingBy: 1000))
                
                print("Distance between locations: \(distanceInKm) Km \(distanceInMeter) m")
                self.LblShowDistance.text! = "Distance is \(distanceInKm) Km \(distanceInMeter) m"
                
                self.drawRoute(startCoordinate: firstLocation.coordinate, destinationCoordinate: secondLocation.coordinate)
            }
        }
        
    }
    //Calculate distance between two places-----End
    
    
    // Draw Route between two places ----- Start
    func drawRoute(startCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D){
        
        print("draw route-----------")
        
        let sourcePlacemark = MKPlacemark(coordinate: startCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirections.Request()
        request.source = sourceItem
        request.destination = destinationItem
        request.transportType =  .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let route = response?.routes.first else{
                if let error = error{
                    print("Error calculating directions:--------------------- \(error.localizedDescription)")
                }
                return
            }
            
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    // Draw Route between two places ----- End
    
    
    //Add rippple animation start
    
    func createPulse(at coordinate: CLLocationCoordinate2D) {
        
        // Remove previous pulseLayer
        pulseLayer?.removeFromSuperlayer()
        
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 20, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        print("Coordinate from Pulse animation ----- \(coordinate)")
        
        let newPulseLayer = CAShapeLayer()
        newPulseLayer.path = circularPath.cgPath
        newPulseLayer.lineWidth = 2.0
        newPulseLayer.fillColor = UIColor.clear.cgColor
        newPulseLayer.strokeColor = UIColor.blue.cgColor
        newPulseLayer.lineCap = CAShapeLayerLineCap.round
        newPulseLayer.position = mapView.convert(coordinate, toPointTo: mapView)
        
        mapView.layer.addSublayer(newPulseLayer)
        
        
        // Assign the new layer to the instance variable
        pulseLayer = newPulseLayer
        
        if let pulseLayer = pulseLayer {
            mapView.layer.addSublayer(pulseLayer)
            
            // Animation
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 1.5
            pulseAnimation.fromValue = 0.5
            pulseAnimation.toValue = 1.5
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            pulseAnimation.autoreverses = false
            pulseAnimation.repeatCount = .infinity
            pulseLayer.add(pulseAnimation, forKey: "pulse")
        }
    }
    
    //Add rippple animation end
    
    
    //Remove rippple animation start
    func removeRippleAnimation() {
        pulseLayer?.removeFromSuperlayer()
        pulseLayer = nil // Set pulseLayer to nil to release the reference
    }
    
    //Remove rippple animation end
    
    
    //Function for warning message----Start
    
    func showToast(controller:UIViewController ,message:String,seconds:Double){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15
        let CancelBtn = UIAlertAction(title: "Close", style: .destructive)
        alert.addAction(CancelBtn)
        
        controller.present(alert, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + seconds)
        {
            alert.dismiss(animated: true)
        }
    }
    
    //Function for warning message----End
    
    
    //API call for country-----Start
    func APIDataPass() {
        AF.request(base_url, method: .get).responseDecodable(of: [APIData].self) { response in
            debugPrint("response from API:-------------------\(response)")
            
            switch response.result {
            case .success(let data):
                print("Data from API:------\(data)")
                
                var limitData: [APIData] = []
                
                for item in data {
                    limitData.append(item)
                    if limitData.count == 10 {
                        break
                    }
                }
                
                self.apiItems = limitData
                // let count = self.apiItems.count
                self.collectionViewObj.reloadData()
                
                //pagingation
                
                self.PageControl.drawer = ExtendedDotDrawer(height: 10, width: 10, space: 8, raduis: 10, indicatorColor: UIColor.blue,dotsColor: .gray,isBordered: false,borderWidth: 0.0,indicatorBorderColor: .clear,indicatorBorderWidth: 0.0)
                self.PageControl.numberOfPages = limitData.count
                
                
            case .failure(let error):
                print("Error:-------\(error)")
            }
        }
    }
    
    
    //API call for country-----End
    
    
    
}


//extension for  tableview
extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let result = searchResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: result)
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let coordinate = response?.mapItems[0].placemark.coordinate else {
                return
            }
            
            guard let name = response?.mapItems[0].name else {
                return
            }
            
            print(name)
            
            let lat = coordinate.latitude
            let lon = coordinate.longitude
            
            print(lat)
            print(lon)
            
            
            self.searchResultsTable.isHidden = true
            self.updateLocation(lat: lat, log: lon,title:name)
            
            
        }
        
    }
    
    func updateLocation(lat: CLLocationDegrees, log: CLLocationDegrees,title:String) {
        self.isValid = true
        let coordinate = CLLocationCoordinate2D(latitude: lat,longitude: log)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        pin.title=title
        mapView.addAnnotation(pin)
        self.mKPointAnnotation.append(pin)
        
        //update textfield value after loaction selected
        if sourceActive {
            searchBar.text = title
            
        } else {
            destinationSearch.text = title
        }
        
        self.searchResultsTable.isHidden = true
        self.ZoomBtnStack.isHidden = false
    }
    
}

//Extension for route
extension ViewController: MKMapViewDelegate{
    //Draw route
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 3.0
        return renderer
    }
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let coordinate = mapView.centerCoordinate
        if self.isValid {
            print("Valid Location----\(self.isValid)")
            self.isValid = false
            createPulse(at: coordinate)
        }
    }
}

//Extension for zoom Button

extension ViewController
{
    func zoomMapView(byfactor factor:Double)
    {
        var region = mapView.region
        var span = mapView.region.span
        
        span.latitudeDelta *= factor
        span.longitudeDelta *= factor
        
        region.span = span
        mapView.setRegion(region, animated: true)
    }
}

//extension of collectionView

extension ViewController: UICollectionViewDataSource,UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        print("Countries count------\(apiItems.count)")
        return apiItems.count
        
    }
    
    
    //Update collection view data with API
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionViewObj.dequeueReusableCell(withReuseIdentifier: "CountriesCollectionViewCell", for: indexPath) as! CountriesCollectionViewCell
        
        cell.layer.cornerRadius = 50.0
        
        cell.delegate = self
        
        let item = apiItems[indexPath.item]
        let imageURL = URL(string: item.flags.png)
        cell.FlagImg.af.setImage(withURL: imageURL!)
        cell.lblCountryName.text = item.name.common
        
        return cell
    }
    
    
    //Add pagination to the scrollView
     func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let layout = self.collectionViewObj.collectionViewLayout as! UPCarouselFlowLayout
            let pageSize = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
            let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
           
           let currentPage = Int(floor((offset - pageSize / 2) / pageSize) + 1)
         
           print("Current Page-----\(currentPage)")
         
          PageControl.setPageOffset(floor((offset - pageSize / 2) / pageSize) + 1)
        }
    
    
    
    
    
    
}

extension ViewController: showCountryBtnDelegate{
    
    // showCountry Loaction Func start-----
    func buttonTapped(cell: CountriesCollectionViewCell) {
        
        if self.apiItems.count > 0 {
            if let indexPath = collectionViewObj.indexPath(for: cell) {
                print("IndexPath:----\(indexPath.row)")
                let selectedItem = apiItems[indexPath.row]
                let latitude = selectedItem.latlng.first ?? 0.0
                let longitude = selectedItem.latlng.last ?? 0.0
                print("latitude:--- \(latitude), longitude:--- \(longitude)")
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let region = MKCoordinateRegion(center: coordinate, span: span)
                
                mapView.setRegion(region, animated: true)
                
                let pin = MKPointAnnotation()
                pin.coordinate = coordinate
                pin.title = selectedItem.name.common
                print("Country Name------\(selectedItem.name.common)")
                mapView.addAnnotation(pin)
            }
        }
    }
    
    // showCountry Loaction Func End-----
}






