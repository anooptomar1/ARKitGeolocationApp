import UIKit
import SceneKit
import ARKit
import CoreLocation
import Alamofire
import GoogleMaps

class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {

    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet var arSceneView: ARSCNView!
    
    @IBOutlet weak var btnMapCamera: UIButton!
    let HORIZONTAL_ACCURACY: Double = 11
    let GEO_FENCE_RADIUS: Double = 50
    let locationManager = CLLocationManager()
    
    var points: [ModelData] = []
    var loadedModels : [Int] = []
    let infoLabel: UILabel = UILabel(frame: CGRect(x: 20, y: 20, width: 180, height: 90))
    
    var isSceneLoaded: Bool = false;
    var isModelLoading: Bool = false;
    var isModelLoaded: Bool = false;
    var loadedModelD: ModelData = ModelData()
    
    var isInited: Bool = false;
    var jsonMapData: NSArray = []
    var currentLocationManager = CLLocationManager()
    var currentLocation:CLLocation?
    var locModelInitialZ:Float = 0.0
    
    var isInitialLoad: Bool = false;
    var screenCenter: CGPoint?
    var currentNode : SCNNode?
    var currentPlaneNode : SCNNode?
    var session = ARSession()
    var isPlaneSelected = false
    var isHiddenLog = true
    //let possibleZMinus: Float = 4.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.screenCenter = self.arSceneView.bounds.mid
        }
        
        
        // let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
       //                                       longitude: defaultLocation.coordinate.longitude,
      //                                        zoom: zoomLevel)
        mapView.settings.myLocationButton = true
        //mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        self.mapView.isHidden = true
        mapView.animate(toZoom: 18)
        self.callAPIForGetAllPin()
        
        //Setup info label
        setupLabel()
        
        //Launch services
        startLocationing()
        
        // Set the view's delegate
        
        arSceneView.delegate = self
        setupFocusSquare()
        //Load JSON, parse and update data in monitoring on response
        updateDataAPI()
        
        self.checkCameraAccess()
    }

    @IBAction func btnScreenCaptureClick(_ sender: UIButton)
    {
        UIGraphicsBeginImageContextWithOptions(arSceneView.bounds.size, false, UIScreen.main.scale)
        
        UIImageWriteToSavedPhotosAlbum(arSceneView.snapshot(), self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    //MARK: - Add image to Library
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    func checkCameraAccess()
    {
        let deviceHasCamera = UIImagePickerController.isSourceTypeAvailable(.camera)
        if (deviceHasCamera) {
            let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            switch authStatus {
            case .authorized: self.showCameraView(btnMapCamera)
            case .denied: alertPromptToAllowCameraAccessViaSettings()
            default: break
            }
        } else {
            let alertController = UIAlertController(title: "Error", message: "Device has no camera", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
            })
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func setupLabel() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapResponse(recognizer:)))
        tapGesture.numberOfTapsRequired = 1
        Factories.updateLabel(infoLabel: self.infoLabel, recognizer: tapGesture)
        arSceneView.addSubview(infoLabel)
        arSceneView.bringSubview(toFront: infoLabel)
        infoLabel.isHidden = isHiddenLog
    }
    
    func tapResponse(recognizer: UITapGestureRecognizer) {
        exit(0)
    }
    
    func startLocationing() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.requestAlwaysAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        locationManager.headingFilter = 1;
        locationManager.startUpdatingHeading()
    }

    func add3dText(text: String, yOffset: Float, direction: CLLocationDirection, location: CLLocation, point: ModelData) {
        let textNode = Factories.getTextNode(text: text)
        let rotateAction = SCNAction.rotate(by: CGFloat(direction * .pi / 180), around: SCNVector3Make(0, 1, 0), duration: 1)
        textNode.runAction(rotateAction)
        textNode.position = Utils.updatePosition(point: point, location: location, direction: direction, yOffset: yOffset, locationModelInitialZ: 0.0)
        arSceneView.scene.rootNode.addChildNode(textNode)
    }
    
    func loadScene(point: ModelData, direction: CLLocationDirection?, location: CLLocation, locationModelInitialZ: Float) {
        if direction == nil { return }
        
        var documentsURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        documentsURL.appendPathComponent(String(point.locId) + ".scnassets")
        documentsURL.appendPathComponent(Utils.getLastPathElementInUrl(url: point.locModelFile))
        let sceneSource = SCNSceneSource(url: documentsURL, options: nil)!
        var scene : SCNScene = SCNScene()
        do {
            //try arSceneView.scene = scene.scene(options: nil)
            try scene = sceneSource.scene(options: nil)
        } catch {
            self.handleLoadingFail()
            self.locationManager.startUpdatingHeading()
            self.currentLocationManager.startUpdatingHeading()
            //self.infoLabel.text = "Scene load failed, reloading..."
            return
        }

        //load model
        let node = scene.rootNode.childNode(withName: "SketchUp", recursively: true)
        //geo compensating
        //node?.position = Utils.updatePosition(point: point, location: location, direction: direction!, yOffset: point.locModelInitialZ , locationModelInitialZ: locationModelInitialZ) // - possibleZMinus
        node?.scale = SCNVector3(point.locModelScale, point.locModelScale, point.locModelScale)
        
        let physicsBody = SCNPhysicsBody(
            type: .kinematic,
            shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.1))
        )
        node?.physicsBody = physicsBody
        node?.movabilityHint = .movable
        
        var newTranform = SCNMatrix4Identity
        newTranform = SCNMatrix4Translate(newTranform, point.locModelInitialZ, point.locModelInitialY, point.locModelInitialX)
        newTranform =  SCNMatrix4Rotate(newTranform, GLKMathDegreesToRadians(point.locModelInitialRotY), 0, 1, 0)
        
        node?.eulerAngles = SCNVector3(0, GLKMathDegreesToRadians(point.locModelInitialRotY), 0)
        
        node?.position = SCNVector3(newTranform.m41, newTranform.m42, newTranform.m43)
        
        currentNode = node
        
        print ("Added scene node")
        arSceneView.addSubview(infoLabel)
        //add3dText(text: String(point.locId), yOffset: -2, direction: direction!, location: location, point: point)
        arSceneView.bringSubview(toFront: infoLabel)
        isSceneLoaded = true
    }
    
    func updateDataAPI() {
        let lat = locationManager.location?.coordinate.latitude
        let lon = locationManager.location?.coordinate.longitude
        if lat == nil || lon == nil || isInited { return }
        isInited = true;
        

        Alamofire.request("http://pindropar.com/api/v1/locations/all?lat=\(lat!)&lon=\(lon!)&direction=90&max_distance=999999999").responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            let data = response.data!
            let utf8Text = String(data: data, encoding: .utf8)!
            weak var weakSelf = self
            let pointsResponse = [ModelData](json: utf8Text)
            if pointsResponse.count > 19 {
                weakSelf!.points = Array(pointsResponse.dropLast(pointsResponse.count - 19))
            }
            else {
                weakSelf!.points = pointsResponse
            }
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
                self.jsonMapData = (json as! NSArray)
            }
            
        }
    }
    // not used
    func jsonProcessed() {
        updateMonitoring(points: points)
        if (locationManager.location != nil &&
            !isSceneLoaded &&
            locationManager.location!.horizontalAccuracy < HORIZONTAL_ACCURACY &&
            locationManager.heading != nil) {
            self.infoLabel.text = "Coords: lat \(locationManager.location!.coordinate.latitude) lon \(locationManager.location!.coordinate.longitude)"
            self.infoLabel.text = "Coords: lat \(locationManager.location!.coordinate.latitude) lon \(locationManager.location!.coordinate.longitude) Heading is \(Int(locationManager.heading!.trueHeading)) No location or GPS"
            let nearest = Utils.isInAreaOf(radius: GEO_FENCE_RADIUS, location: locationManager.location!, points: points)
            if nearest != nil && !isModelLoading {
                proceedLoadModel(nearest: nearest!, direction: locationManager.heading!.trueHeading, location: locationManager.location!)
            }
        }
    }
    
    func proceedLoadModel(nearest: ModelData, direction: CLLocationDirection, location: CLLocation) {
        if isModelLoading { return }
        
        isModelLoading = true
        loadedModelD = nearest
        let fileName: String = Utils.getLastPathElementInUrl(url: nearest.locModelFile)
        self.infoLabel.text = "Coords: lat \(location.coordinate.latitude) lon \(location.coordinate.longitude) Heading \(Int(direction)) Loading id \(nearest.locId)"
        let urls: [URL] = [URL(string: nearest.locModelFile)!]
        let filenames: [String] = [fileName]
        let subfolder = String(nearest.locId) + ".scnassets"
        
        if !nearest.locTextureFile.isEmpty
        {
            let filename: String = nearest.locTextureFile.components(separatedBy: "/").last!
            //let pathExtention = filename.components(separatedBy: ".").last
            let pathPrefix = filename.components(separatedBy: ".").first
            
            let zipURL:URL = URL.init(string: nearest.locTextureFile)!
            
            Downloader.loadAlamoForZip(url: zipURL, subfolder: subfolder, filename: pathPrefix!, completionHandler: {(flag: Bool) -> Void in
                print("model and textures downloaded")
                self.isModelLoaded = true
                Downloader.loadList(urls: urls, subfolder: subfolder, filenames: filenames, completionHandler: {(flag: Bool) -> Void in
                    print("model and textures downloaded")
                    self.isModelLoaded = true
                    self.infoLabel.text = "Coords: lat \(location.coordinate.latitude) lon \(location.coordinate.longitude) Heading is \(Int(direction)) Loaded: \(fileName))"
                    self.locationManager.requestLocation()
                })
            }, failure: {
                self.isModelLoaded = false
                self.isModelLoading = false
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if isModelLoaded &&
            manager.location != nil &&
            !isSceneLoaded
            && manager.heading != nil
        {
            let location = manager.location!
            let nearest = loadedModelD
            self.infoLabel.text = "Coords: lat \(location.coordinate.latitude) lon \(location.coordinate.longitude) Heading:\(Int(newHeading.trueHeading)) Id:\(nearest.locId) Name:\(Utils.getLastPathElementInUrl(url: nearest.locModelFile)) GPS off"
            self.loadScene(point: nearest, direction: newHeading.trueHeading, location: location, locationModelInitialZ: nearest.locModelInitialRotZ)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if !isInited {
            updateDataAPI()
            return
        }
        if !isSceneLoaded && !isModelLoading {
            self.infoLabel.text = "No GPS data"
            if locations.count > 0 {
                if locations.last!.horizontalAccuracy > 5 { self.infoLabel.text = "GPS Aquired. Accuracy is low: \(locations.last!.horizontalAccuracy)" }
                else { self.infoLabel.text = "GPS Aquired. Processing." }
            }
        }
        
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        //let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
        //                                      longitude: location.coordinate.longitude,
        //                                      zoom: 15.0)
        
       // mapView.animate(to: camera)
        
        if isInitialLoad == false
        {
            isInitialLoad = true
            mapView.animate(toLocation: (locations.last?.coordinate)!)
        }
        
        if locations.count > 0 &&
            !isSceneLoaded &&
            locations.last!.horizontalAccuracy < HORIZONTAL_ACCURACY &&
            manager.heading != nil {
            let location = locations.last!
            if points.count > 0 && !isModelLoading {
                let nearest = Utils.isInAreaOf(radius: GEO_FENCE_RADIUS, location: location, points: points)
                self.infoLabel.text = "Coords: lat \(location.coordinate.latitude) lon \(location.coordinate.longitude) Heading is \(Int(manager.heading!.trueHeading)) No close location"
                if nearest != nil {
                    proceedLoadModel(nearest: nearest!, direction: manager.heading!.trueHeading, location: location)
                }
            }
            if isModelLoaded && manager.heading != nil && locations.count > 0 {
                let nearest = loadedModelD
                let location = locations.last!
                self.infoLabel.text = "Coords: lat \(location.coordinate.latitude) lon \(location.coordinate.longitude) Heading:\(Int(manager.heading!.trueHeading)) Id:\(nearest.locId) Name:\(Utils.getLastPathElementInUrl(url: nearest.locModelFile)) GPS off"
                let heading = manager.heading!
                self.loadScene(point: nearest, direction: heading.trueHeading, location: location, locationModelInitialZ: nearest.locModelInitialRotZ)
            }
        }
    }
    
    private func handleLoadingFail() {
        self.isSceneLoaded = false
        self.isModelLoading = false
        self.isModelLoaded = false
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if region != nil { print("Monitoring failed: \(region!.identifier)") }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with error: \(error)")
    }
    
    func updateMonitoring(points: [ModelData]) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle: "Error", message: "GeoFencing is not available!")
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert(withTitle:"Warning", message: "Geotification updated but not permitted.")
        }
        let monitoredRegions: Set<CLRegion> = locationManager.monitoredRegions
        
        //Updating points for monitoring
        for value in monitoredRegions {
            let regid = value.identifier
            var isFound: Bool = false
            for point in points {
                let pointId = ViewController.getDescription(point: point)
                if pointId == regid { isFound = true }
            }
            if !isFound { locationManager.stopMonitoring(for: value) }
        }
        
        let updatedMonitoredRegions: Set<CLRegion> = locationManager.monitoredRegions
        for point in points {
            var isFound: Bool = false
            for value in updatedMonitoredRegions {
                let pointId = ViewController.getDescription(point: point)
                if pointId == value.identifier { isFound = true }
            }
            if !isFound { addMonitoringPoint(point: point)}
        }
    }
    
    static func getDescription(point: ModelData) -> String {
        return "You are approaching \(point.locNotes) at lat:\(String(format: "%.4f", point.locLat)) lon:\(String(format: "%.4f", point.locLon))"
    }
    
    func addMonitoringPoint(point: ModelData) {
        var radius = GEO_FENCE_RADIUS
        if (radius > locationManager.maximumRegionMonitoringDistance) {
            radius = locationManager.maximumRegionMonitoringDistance
        }
        let lat: CLLocationDegrees = point.locLat
        let longit: CLLocationDegrees = point.locLon
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: longit), radius: radius, identifier: ViewController.getDescription(point: point))
        region.notifyOnEntry = true;
        
        locationManager.startMonitoring(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

    }
    
    @IBAction func btnMapClicked(_ sender: UIButton) {
       if sender.tag == 1
       {
            self.showMapView(sender)
       }
       else
       {
            self.checkCameraAccess()
            //self.showCameraView(sender)
        }
    }
    
    func showCameraView(_ sender: UIButton)
    {
        sender.tag = 1
        self.arSceneView.isHidden = false
        self.mapView.isHidden = true
        sender.setImage(UIImage.init(named: "map"), for: .normal)
    }
    
    func showMapView(_ sender: UIButton)
    {
        setupMapPins()
        isInitialLoad = false
        self.arSceneView.isHidden = true
        self.mapView.isHidden = false
        
        sender.tag = 2
        sender.setImage(UIImage.init(named: "camera"), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arSceneView.session = session
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        points = []
        isSceneLoaded = false;
        isModelLoading = false;
        isModelLoaded = false;
        loadedModelD = ModelData()
        session.pause()
        exit(0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
//-----------------------------ARKit Part---------------------------------------
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?,
        planeAnchor: ARPlaneAnchor?,
        hitAPlane: Bool) {
            
            // -------------------------------------------------------------------------------
            // 1. Always do a hit test against exisiting plane anchors first.
            //    (If any such anchors exist & only within their extents.)
            
            let planeHitTestResults = arSceneView.hitTest(position, types: .existingPlaneUsingExtent)
            if let result = planeHitTestResults.first {
                
                let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
                let planeAnchor = result.anchor
                
                // Return immediately - this is the best possible outcome.
                return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
            }
            
            // -------------------------------------------------------------------------------
            // 2. Collect more information about the environment by hit testing against
            //    the feature point cloud, but do not return the result yet.
            
            var featureHitTestPosition: SCNVector3?
            var highQualityFeatureHitTestResult = false
            
            let highQualityfeatureHitTestResults =
                arSceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
            
            if !highQualityfeatureHitTestResults.isEmpty {
                let result = highQualityfeatureHitTestResults[0]
                featureHitTestPosition = result.position
                highQualityFeatureHitTestResult = true
            }
            
            // -------------------------------------------------------------------------------
            // 3. If desired or necessary (no good feature hit test result): Hit test
            //    against an infinite, horizontal plane (ignoring the real world).
            
            if (infinitePlane || !highQualityFeatureHitTestResult) {
                
                let pointOnPlane = objectPos ?? SCNVector3Zero
                
                let pointOnInfinitePlane = arSceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
                if pointOnInfinitePlane != nil {
                    return (pointOnInfinitePlane, nil, true)
                }
            }
            
            // -------------------------------------------------------------------------------
            // 4. If available, return the result of the hit test against high quality
            //    features if the hit tests against infinite planes were skipped or no
            //    infinite plane was hit.
            
            if highQualityFeatureHitTestResult {
                return (featureHitTestPosition, nil, false)
            }
            
            // -------------------------------------------------------------------------------
            // 5. As a last resort, perform a second, unfiltered hit test against features.
            //    If there are no features in the scene, the result returned here will be nil.
            
            let unfilteredFeatureHitTestResults = arSceneView.hitTestWithFeatures(position)
            if !unfilteredFeatureHitTestResults.isEmpty {
                let result = unfilteredFeatureHitTestResults[0]
                return (result.position, nil, false)
            }
            
            return (nil, nil, false)
    }
    // MARK: - Focus Square
    var focusSquare: FocusSquare?

    
    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        focusSquare?.unhide()
        arSceneView.scene.rootNode.addChildNode(focusSquare!)
    }
  
    func updateFocusSquare() {
       
        guard let screenCenter = screenCenter else { return }
        let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, objectPos: focusSquare?.position)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.arSceneView.session.currentFrame?.camera)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let results = arSceneView.hitTest(touch.location(in: arSceneView), types: .existingPlaneUsingExtent)
        guard let hitFeature = results.first else {return}
        let newLocation = SCNVector3Make(hitFeature.worldTransform.columns.3.x, hitFeature.worldTransform.columns.3.y, hitFeature.worldTransform.columns.3.z)
        if currentNode != nil && !isLoadedModel(locId: loadedModelD.locId){
            let node = currentNode?.clone()
            
            node?.position =  newLocation + (node?.position)!
            
//            currentPlaneNode?.addChildNode(node!)
            arSceneView.scene.rootNode.addChildNode(node!)
            loadedModels.append(loadedModelD.locId)
        }else{
            self.infoLabel.text = "There is no model to place on the plane"
        }
    }
    
    func isLoadedModel(locId : Int) -> Bool{
        for i in loadedModels {
            if i == locId{
                return true
            }
        }
        return false
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // add the anchor node only if the plane is not already selected.
        /*guard !isPlaneSelected else {
            // we don't session to track the anchor for which we don't want to map node.
            arSceneView.session.remove(anchor: anchor)
            return nil
        }*/
        if (currentNode == nil){
            return nil
        }
        var planeNode:  SCNNode?
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeGeometry = SCNBox(width: CGFloat(planeAnchor.extent.x), height: 0.01, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0.0)
            planeGeometry.firstMaterial?.diffuse.contents = UIColor.clear
            planeGeometry.firstMaterial?.specular.contents = UIColor.white
            planeNode = SCNNode(geometry: planeGeometry)
            planeNode?.position = SCNVector3Make(planeAnchor.center.x, Float(0.01 / 2), planeAnchor.center.z)
            currentPlaneNode = planeNode
        } else {
            // haven't encountered this scenario yet
            print("not plane anchor \(anchor)")
        }
        return planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime tisme: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
    }
   
}

extension ViewController
{
    func setupMapPins()
    {
        self.mapView.clear()
        for index in 0..<jsonMapData.count
        {
            let dictData:NSDictionary = jsonMapData.object(at: index) as! NSDictionary
            
            let lat = CLLocationDegrees.init(Double(dictData.object(forKey: "loc_lat") as! String)!)
            let long = CLLocationDegrees.init(Double(dictData.object(forKey: "loc_lon") as! String)!)
            
            let position = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let marker = GMSMarker(position: position)
            marker.title = (dictData.object(forKey: "loc_notes") as? String)!
            marker.icon = UIImage.init(named: "pin")
            marker.map = mapView
        }
       // mapView.isMyLocationEnabled = true
    }
    
    func callAPIForGetAllPin()
    {
        Alamofire.request("http://pindropar.com/api/v1/locations/all?lat=50.427959&lon=30.535443&direction=90&max_distance=999999999").responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
                self.jsonMapData = (json as! NSArray)
                
            }
        }
    }
}

extension ViewController
{
    func alertPromptToAllowCameraAccessViaSettings() {
        let alert = UIAlertController(title: "\"GeoARDJ\" Would Like To Access the Camera", message: "Please grant permission to use the Camera so that you can access camera to capture.", preferredStyle: .alert )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .cancel) { alert in
            self.open(scheme: UIApplicationOpenSettingsURLString)
        })
        present(alert, animated: true, completion: nil)
    }
    
    func open(scheme: String) {
        if let url = URL(string: scheme) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:],
                                          completionHandler: {
                                            (success) in
                                            print("Open \(scheme): \(success)")
                })
            } else {
                let success = UIApplication.shared.openURL(url)
                print("Open \(scheme): \(success)")
            }
        }
    }
    
    
    func permissionPrimeCameraAccess() {
        
    }
    
    @IBAction func ShowDebugLogo(_ sender: Any) {
        isHiddenLog = !isHiddenLog
        infoLabel.isHidden = isHiddenLog
    }
    
}

