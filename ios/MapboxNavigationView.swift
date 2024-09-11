
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps
import Polyline


extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

class MapboxNavigationView: UIView, NavigationViewControllerDelegate,
                            NavigationServiceDelegate,

NavigationMapViewDelegate{
    weak var navViewController: NavigationViewController?
    
    var mapView : NavigationMapView?
    var embedded: Bool
    var embedding: Bool
    
    
    
    @objc var startOrigin: NSArray = [] {
        didSet { setNeedsLayout() }
    }
    
    var waypoints: [Waypoint] = [] {
        didSet { setNeedsLayout() }
    }
    
    func setWaypoints(coordinates: [CLLocationCoordinate2D]) {
        waypoints = coordinates.map { Waypoint(coordinate: $0) }
    }
    
    var stops: [[String: Any]] = [] {
        didSet { setNeedsLayout() }
    }
    
    
    
    func setStops(data: [[String: Any]]) {
        stops = data
        
    }
    
    
    private func fetchImage(from uri: String) -> UIImage? {
        guard let url = URL(string: uri) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            print("Error fetching image: \(error)")
            return nil
        }
    }
    
    
    
    
    @objc var destination: NSArray = [] {
        didSet { setNeedsLayout() }
    }
    
    @objc var shouldSimulateRoute: Bool = false
    @objc var showsEndOfRouteFeedback: Bool = false
    @objc var showCancelButton: Bool = false
    @objc var hideStatusView: Bool = false
    @objc var mute: Bool = false
    @objc var language: NSString = "us"
    
    @objc var onLocationChange: RCTDirectEventBlock?
    @objc var onRouteProgressChange: RCTDirectEventBlock?
    @objc var onError: RCTDirectEventBlock?
    @objc var onCancelNavigation: RCTDirectEventBlock?
    @objc var onArrive: RCTDirectEventBlock?
    @objc var vehicleMaxHeight: NSNumber?
    @objc var vehicleMaxWidth: NSNumber?
    
  
    @objc var isPreview: Bool = false
    
    @objc var waypointMarker: UIImage = UIImage()
    
    
    override init(frame: CGRect) {
        self.embedded = false
        self.embedding = false
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (navViewController == nil && !embedding && !embedded) {
            embed()
        } else {
            navViewController?.view.frame = bounds
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        // cleanup and teardown any existing resources
        self.navViewController?.removeFromParent()
    }
    
    private func embed() {
        guard startOrigin.count == 2 && destination.count == 2 else { return }
        
        embedding = true
        
        
     
       
        
       
   
            
            
            
            
            let originWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: startOrigin[1] as! CLLocationDegrees, longitude: startOrigin[0] as! CLLocationDegrees))
            var waypointsArray = [Waypoint]()
            
      
            waypointsArray.append(originWaypoint)
           
            
            for item in stops {
                
                
                if let cor = item["coordinates"] as? [Double] {
                    if cor.count  == 2 {
                        
                        let point = CLLocationCoordinate2D(latitude:cor[1] , longitude: cor[0])
                        
                        let wPoint = Waypoint(coordinate: point, name: (item["name"] as! String))
                        waypointsArray.append(wPoint)
                        
                        
                        
                        
                    }
                    
                } else {
                    print("coordinates not found or invalid format")
                }
                
                
                
            }
            
            
            
            
            
            
            let destinationWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: destination[1] as! CLLocationDegrees, longitude: destination[0] as! CLLocationDegrees))
            waypointsArray.append(destinationWaypoint)
            
            
            
            
            let options = NavigationRouteOptions(waypoints: waypointsArray, profileIdentifier: .automobileAvoidingTraffic)
            options.includesAlternativeRoutes = false
            
            let locale = "en"
            options.locale = Locale(identifier: locale)
            
            
            
            Directions.shared.calculateRoutes(options: options) { [weak self] result in
                guard let strongSelf = self, let parentVC = strongSelf.parentViewController else {
                    return
                }
                
                switch result {
                case .failure(let error):
                    strongSelf.onError!(["message": error.localizedDescription])
                case .success(let response):
                    
                    
                    
                    if strongSelf.isPreview {
                        var pHight = strongSelf.bounds.height
                        var pWidth = (strongSelf.bounds.width)
                        
                        if pWidth == 0 {
                            pWidth = 200
                        }
                        if  pHight == 0 {
                            
                            pHight = pWidth
                            
                        }
                        
                        
                        strongSelf.frame = CGRect(x: 0, y: 0, width: pWidth, height: pHight)
                        
                        
                        let mapView = NavigationMapView(frame: CGRect(x: 0, y: 0, width: pWidth, height: pHight))
                       // let cameraOptions = CameraOptions(center:
                                                    //        CLLocationCoordinate2D(latitude: 39.5, longitude: -98.0),
                                                     //     zoom: 20, bearing: 0, pitch: 0)
                        
                        
                        mapView.delegate = strongSelf
                       
                        
                        //mapView.mapView.mapboxMap.setCamera(to: cameraOptions)
                        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        
                        strongSelf.addSubview(mapView)
                        mapView.showcase(response.routeResponse.routes!,routesPresentationStyle:.all(shouldFit: true, cameraOptions: CameraOptions(padding: UIEdgeInsets(top: 40, left: 40, bottom: 80, right: 40)) ))
                        
                        strongSelf.mapView = mapView
                        
                        
                        
                    }
                    
                    else{
                        
                   
                    
                    
                    
                    let navigationOptions = NavigationOptions(simulationMode:  .never)
                    let vc = NavigationViewController(for: response, navigationOptions: navigationOptions)
                    
                    vc.showsEndOfRouteFeedback = strongSelf.showsEndOfRouteFeedback
                    StatusView.appearance().isHidden = true
                    
                    NavigationSettings.shared.voiceMuted = strongSelf.mute;
                    
                    
                    vc.delegate = strongSelf
                    self!.navViewController = vc
                    
                    
                 
                            
                    
                    
                    parentVC.addChild(vc)
                    strongSelf.addSubview(vc.view)
                    vc.view.frame = strongSelf.bounds
                    vc.didMove(toParent: parentVC)
                    strongSelf.navViewController = vc
                    vc.navigationMapView?.delegate = self
                    
                    
                    }
                    
                    
                    
                }
                
                strongSelf.embedding = false
                strongSelf.embedded = true
            }
        
    }
    
    
    
    // MARK: - Styling methods
    func customCircleLayer(with identifier: String, sourceIdentifier: String) -> CircleLayer {
        
        var circleLayer = CircleLayer(id: identifier)
        circleLayer.source = sourceIdentifier
        let opacity = Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        }
        circleLayer.circleColor = .constant(.init(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
        circleLayer.circleOpacity = .expression(opacity)
        
        circleLayer.circleRadius = .constant(.init(0))
        circleLayer.circleStrokeColor = .constant(.init(UIColor.black))
        circleLayer.circleStrokeWidth = .constant(.init(0))
        circleLayer.circleStrokeOpacity = .expression(opacity)
        return circleLayer
    }
    
    func customSymbolLayer(with identifier: String, sourceIdentifier: String) -> SymbolLayer {
        var symbolLayer = SymbolLayer(id: identifier)
        symbolLayer.source = sourceIdentifier
        symbolLayer.textField = .expression(Exp(.toString) {
            Exp(.get) {
                "name"
            }
        })
        symbolLayer.textSize = .constant(.init(0))
        symbolLayer.textOpacity = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        })
        symbolLayer.textColor = .constant(.init(UIColor.black))
        
        symbolLayer.textHaloWidth = .constant(.init(0.3))
        symbolLayer.textHaloColor = .constant(.init(UIColor.black))
        return symbolLayer
    }
    
    func customWaypointShape(shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection {
        var features = [Turf.Feature]()
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
            feature.properties = [
                "waypointCompleted": .boolean(waypointIndex < legIndex),
                "name":   .number(Double(waypointIndex + 2))
            ]
            features.append(feature)
        }
        return FeatureCollection(features: features)
    }
    
        func navigationViewController(_ navigationViewController: NavigationViewController, didAdd finalDestinationAnnotation: PointAnnotation, pointAnnotationManager: PointAnnotationManager){
    
        }
    
        func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
             return customWaypointShape(shapeFor: waypoints, legIndex: legIndex)
         }
    
    
        func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
                return customCircleLayer(with: identifier, sourceIdentifier: sourceIdentifier)
            }
    
        func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
               return customSymbolLayer(with: identifier, sourceIdentifier: sourceIdentifier)
           }
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool{
        return false
    }
    
    
    func navigationMapView(_ navigationMapView: NavigationMapView, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
            var lineLayer = LineLayer(id: identifier)
            lineLayer.source = sourceIdentifier
            
            // `identifier` parameter contains unique identifier of the route layer or its casing.
            // Such identifier consists of several parts: unique address of route object, whether route is
            // main or alternative, and whether route is casing or not. For example: identifier for
            // main route line will look like this: `0x0000600001168000.main.route_line`, and for
            // alternative route line casing will look like this: `0x0000600001ddee80.alternative.route_line_casing`.
            lineLayer.lineColor = .constant(.init(identifier.contains("main") ? #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1) : #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 0)))
        
        if isPreview {
            lineLayer.lineWidth = .expression(lineWidthExpression(0.5))
        }
        else{
            lineLayer.lineWidth = .expression(lineWidthExpression(1))
        }
        
        
        
            //lineLayer.lineWidth = .expression(lineWidthExpression(0.5))
            lineLayer.lineJoin = .constant(.round)
            lineLayer.lineCap = .constant(.round)
    
            
            return lineLayer
        }
    
    func navigationMapView(_ navigationMapView: NavigationMapView, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
            var lineLayer = LineLayer(id: identifier)
            lineLayer.source = sourceIdentifier
            
            // Based on information stored in `identifier` property (whether route line is main or not)
            // route line will be colored differently.
            lineLayer.lineColor = .constant(.init(identifier.contains("main") ? #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1) : #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)))
        
        if isPreview {
            lineLayer.lineWidth = .expression(lineWidthExpression(0))
        }
        else{
            lineLayer.lineWidth = .expression(lineWidthExpression(0.0))
        }
        
        //lineLayer.lineWidth = .expression(lineWidthExpression(0.0))
            lineLayer.lineJoin = .constant(.round)
            lineLayer.lineCap = .constant(.round)
            
            return lineLayer
        }
    
    
    func lineWidthExpression(_ multiplier: Double = 1) -> Expression {
           let lineWidthExpression = Exp(.interpolate) {
               Exp(.linear)
               Exp(.zoom)
               
               // It's possible to change route line width depending on zoom level, by using expression
               // instead of constant. Navigation SDK for iOS also exposes `RouteLineWidthByZoomLevel`
               // public property, which contains default values for route lines on specific zoom levels.
               RouteLineWidthByZoomLevel.multiplied(by: multiplier)
           }
           
           return lineWidthExpression
       }
    
    
    
    
    func navigationMapView(_ navigationMapView: NavigationMapView,
                           didAdd finalDestinationAnnotation: PointAnnotation,
                           pointAnnotationManager: PointAnnotationManager) {
        
        
        
        
                  var finalDestinationAnnotation = finalDestinationAnnotation
                finalDestinationAnnotation.image = .init(image: UIImage(), name: "marker")
        
                  pointAnnotationManager.annotations = [finalDestinationAnnotation]
       //  pointAnnotationManager.delegate = self
        
        
        
        
        self.addStopMarker(data: self.stops, mapView: navigationMapView)
        
        
    }
    
    
    
    
    
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        
        
        
        onLocationChange?([
            "longitude": location.coordinate.longitude,
            "latitude": location.coordinate.latitude,
            "heading": 0,
            "accuracy": location.horizontalAccuracy.magnitude
        ])
        onRouteProgressChange?([
            "distanceTraveled": progress.distanceTraveled,
            "durationRemaining": progress.durationRemaining,
            "fractionTraveled": progress.fractionTraveled,
            "distanceRemaining": progress.distanceRemaining
        ])
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        if (!canceled) {
            return;
        }
        onCancelNavigation?(["message": ""]);
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        onArrive?(["message": ""]);
        return true;
    }
    public func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        
        return false
    }
    
    private func createSampleView(withText text: String,width:CGFloat?,height:CGFloat?,markerText:String) -> UIView {
        
        
        if isPreview {
            let view = UIView()
            view.backgroundColor = .white
            let lbl = UILabel()
                
            lbl.font = .systemFont(ofSize: 13, weight: .semibold)
            lbl.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            lbl.text = text
            lbl.textColor = .black
          
            lbl.textAlignment = .center
            view.addSubview(lbl)
            view.layer.borderWidth = 0.5
                
                // Set the border color
            view.layer.borderColor = UIColor.black.cgColor
                
                // Set the corner radius for rounded corners
                view.layer.cornerRadius = 3
                
                // Enable masksToBounds to ensure the rounded corners are applied
                view.layer.masksToBounds = true
            return view
            
        }
        
        
        let view = UIView()
        
        let markerImage = UIImageView(frame: CGRectMake((width!-30)/2, 0, 30, 30))
        //markerImage.image = waypointMarker
       
        markerImage.contentMode = .scaleAspectFit
        
        view.addSubview(markerImage)
        
        //let markerLbl = UILabel(frame: CGRect(x:6 , y: 2, width: 18, height: 18))
        let markerLbl = UILabel(frame: CGRect(x:0 , y: 0, width: 30, height: 30))
        markerLbl.backgroundColor = .white
        markerLbl.textAlignment = .center
        markerLbl.font = .systemFont(ofSize: 15, weight: .bold)
        markerImage.addSubview(markerLbl)
        markerLbl.layer.cornerRadius = 3
        markerLbl.text = markerText
        markerLbl.textColor = .black
        
        // Enable masksToBounds to ensure the rounded corners are applied
        markerLbl.layer.masksToBounds = true
        
        
        
        

        
        let label = UILabel(frame: CGRect(x: 0, y: 30, width: width!, height: height!))
        
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.textColor = UIColor(red: 152/255, green: 205/255, blue: 236/255, alpha: 1)
        
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.cgColor  // Set the shadow color
        label.layer.shadowOpacity = 1  // Set the shadow opacity (0 to 1)
        label.layer.shadowOffset = CGSize(width: 0, height: 0)  // Set the shadow offset (x, y)
        label.layer.shadowRadius = 0  // Set the blur radius of the shadow
        label.layer.masksToBounds = false
        
        view.addSubview(label)
        return view
        
        
        //return label
        
    }
    
    func heightForText(_ text: String, withFont font: UIFont, width: CGFloat) -> CGFloat {
        // Define the maximum size based on the given width and a large height
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        
        // Create the attributes dictionary with the specified font
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        // Calculate the bounding rect for the text using the maxSize, options, and attributes
        let boundingBox = text.boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        
        // Return the height (boundingBox's height)
        return ceil(boundingBox.height)
    }
    
    
    
    
    
    
    
    
    
    func addStopMarker(data:[[String: Any]],mapView: NavigationMapView){
        
        
        // var arr = [PointAnnotation]()
        // var markerImg : UIImage!
        
     
        
        
        for (index,item) in stops.enumerated() {
            
            
            if let cor = item["coordinates"] as? [Double] {
                if cor.count  == 2 {
                    
                    let font = UIFont.systemFont(ofSize: 16)
                    var text = item["name"]
                    var textWidth = 130.0
                    var textHeight = heightForText(text as! String, withFont: font, width: textWidth)
                    
                    if isPreview{
                        textHeight = 30
                       
                        if index == 0 {
                            text = "Start Point"
                            
                        }
                       else if index == stops.count-1{
                            text = "End Point"
                        }
                        else {
                           // textWidth = 20
                            text = "\(index)"
                        }
                        
                        textWidth = calculateTextWidth(text:text as! String , font: font)
                        if textWidth < 25 {
                            textWidth = 25
                        }
                        
                        textHeight = textHeight-30
                        
                        
                    }
                    
                    
                    
                   
                    
                    
                    
                    let options = ViewAnnotationOptions(
                        geometry: Point(CLLocationCoordinate2D(latitude: cor[1], longitude: cor[0])),
                        width: textWidth,
                        height: textHeight+30,
                        allowOverlap: false,
                        visible: true,
                        anchor: .center,
                        offsetY: 0
                        
                    )
                    
                    // 3. Creating and adding the sample view to the mapView
                    var mText = "\(index)"
                    if index == 0 {
                        mText = "S"
                    }
                    if index == stops.count-1{
                        mText = "D"
                    }
                    let sampleView = createSampleView(withText:text as! String,width: textWidth,height: textHeight, markerText: "\(mText)")
                    if isPreview {
                        try? self.mapView?.mapView.viewAnnotations.add(sampleView, options: options)
                    }
                    else {
                        try? navViewController?.navigationMapView?.mapView.viewAnnotations.add(sampleView, options: options)
                    }
                    
                    
                    
                    
                    
            
                    
                    
                    
                }
                
            } else {
                print("coordinates not found or invalid format")
            }
            
            
            
        }
        
        
        //            if  let pointAnnotationManager = mapView.pointAnnotationManager{
        //
        //                if let idx = pointAnnotationManager.annotations.firstIndex(where: { $0.id.contains("stop") }) {
        //                    pointAnnotationManager.annotations.remove(at: idx)
        //                 }
        //
        //                var newArr = pointAnnotationManager.annotations
        //               newArr.append(contentsOf: arr)
        //                pointAnnotationManager.annotations = newArr
        //            }
        //            else {
        //                print("Here")
        //            }
        
        
        
        
        
        
        
        
        
        
        
        //
        //        for item in points {
        //            var pointAnnotation = PointAnnotation(id: "Driver \(item.latitude) \(item.longitude)", coordinate: item)
        //
        //
        //
        //            pointAnnotation.image = .init(image: UIImage(named: "marker.png")!, name: "mar")
        //            pointAnnotation.iconSize = 0.5
        //            arr.append(pointAnnotation)
        //
        //
        //        }
        //
        //        if ((navViewController) != nil){
        //            let pointAnnotationManager = navViewController?.navigationMapView!.pointAnnotationManager
        //
        //
        //            var newArr = pointAnnotationManager!.annotations
        //            newArr.append(contentsOf: arr)
        //            pointAnnotationManager!.annotations = newArr
        //        }
        //
        //
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
        //            let pointAnnotationManager = navViewController?.navigationMapView!.pointAnnotationManager
        //            //getDetoureRoute(fastRoute: fastRoute)
        //
        //            let myID = "bongo" // id of annotation for deletion.
        //            if let idx = pointAnnotationManager!.annotations.firstIndex(where: { $0.id.contains("Driver") }) {
        //                pointAnnotationManager!.annotations.remove(at: idx)
        //            }
        //
        //
        //
        //        }
        
        
        
        
        
        
    }
    
    
    
    
    
    
    
    func calculateTextWidth(text: String, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        let textSize = (text as NSString).size(withAttributes: attributes)
        
        return textSize.width
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
