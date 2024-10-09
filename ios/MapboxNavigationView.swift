
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
  
  // MARK: -Set stops
  
  var stops: [[String: Any]] = [] {
    didSet { setNeedsLayout() }
  }
  
  
  
  func setStops(data: [[String: Any]]) {
    stops = data
    
  }
  
  // MARK: - Set Driver locations
  
  
  var driverLocations: [[String: Any]] = [] {
    didSet { setNeedsLayout() }
  }
  
  
  
  func setDriverLocations(data: [[String: Any]]) {
    driverLocations = data
    
    
    if driverLocations.count > 0 {
      
      
      if (self.navViewController != nil) {
        addDriver(mapView:(self.navViewController?.navigationMapView)!)
      }
      
      
    }
    else{
      print("No data")
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
  
  // MARK: - init methods
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
  
  
  // MARK: - Init Mapbox
  
  private func embed() {
    
    embedding = true
    
    var waypointsArray = [Waypoint]()
    
    
    
    
    // getting way point from stops data
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
    
    
    //Gettingthe Route from  Direction api
    
    let options = NavigationRouteOptions(waypoints: waypointsArray, profileIdentifier: .automobileAvoidingTraffic)
    options.includesAlternativeRoutes = false
    
    let locale = "en"
    options.locale = Locale(identifier: locale)
    
    
    
    Directions.shared.calculateWithCache(options: options) { [weak self] result in
      guard let strongSelf = self, let parentVC = strongSelf.parentViewController else {
        return
      }
      
      switch result {
      case .failure(let error):
        strongSelf.onError!(["message": error.localizedDescription])
      case .success(let response):
        
        
        
        if strongSelf.isPreview {
          
          //Show map for preview mode only
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
          
          mapView.delegate = strongSelf
          
          mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          
          strongSelf.addSubview(mapView)
          mapView.showcase(response.routeResponse.routes!,routesPresentationStyle:.all(shouldFit: true, cameraOptions: CameraOptions(padding: UIEdgeInsets(top: 40, left: 40, bottom: 80, right: 40)) ))
          
          strongSelf.mapView = mapView
          
          
          
        }
        
        else{
          
          
          //Show map Navigation
          
          
          
          
          
          var opt = PredictiveCacheOptions()
          opt.predictiveCacheNavigationOptions.locationOptions.currentLocationRadius = 2000
          opt.predictiveCacheMapsOptions.locationOptions.destinationLocationRadius = 2000
          opt.predictiveCacheMapsOptions.locationOptions.routeBufferRadius = 2000
          
          var sim = SimulationMode(rawValue: 1)
          sim = .never
          if strongSelf.shouldSimulateRoute {
            sim = .always
          }
          
          let navigationOptions1 = NavigationOptions(  predictiveCacheOptions: opt, simulationMode: sim)
          
          let vc = NavigationViewController(for: response, navigationOptions: navigationOptions1)
          
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
  
  
  // MARK: -Class Methods
  
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
  
  // MARK: - Adding stops to map
  
  func addStopMarker(data:[[String: Any]],mapView: NavigationMapView){
    
    
    let (bgcolor,fgcolor) = getMapTextColor(mapView: mapView)
    
    
    
    for (index,item) in stops.enumerated() {
      
      
      if let cor = item["coordinates"] as? [Double] {
        if cor.count  == 2 {
          
          let font = UIFont.systemFont(ofSize: 16)
          let text = item["name"]
          let textWidth = 130.0
          let textHeight = heightForText(text as! String, withFont: font, width: textWidth)
          
          
          let options = ViewAnnotationOptions(
            geometry: Point(CLLocationCoordinate2D(latitude: cor[1], longitude: cor[0])),
            width: textWidth,
            height: textHeight+30,
            allowOverlap: false,
            visible: true,
            anchor: .center,
            offsetY: 0
            
          )
          
          
          var mText = "\(index)"
          var markerImage = "stopPoint"
          if index == 0 {
            mText = "S"
            markerImage = "startPoint"
          }
          if index == stops.count-1{
            mText = "D"
            markerImage = "endPoint"
          }
          let sampleView = createSampleView(withText:text as! String,width: textWidth,height: textHeight, markerText: "\(mText)", markerImageName: markerImage, bgc: bgcolor,fgc: fgcolor)
          if isPreview {
            //add preview stop marker
            try? self.mapView?.mapView.viewAnnotations.add(sampleView, options: options)
          }
          else {
            //add Navigation stop marker
            try? navViewController?.navigationMapView?.mapView.viewAnnotations.add(sampleView, options: options)
          }
          
          
        }
        
      } else {
        print("coordinates not found or invalid format")
      }
      
      
      
    }
    
    
    
    
  }
  
  // MARK: - Adding and updating drivers location to map (called everytime when drive locations updated)
  
  
  func addDriver(mapView: NavigationMapView){
    
    
    
    for (index,item) in driverLocations.enumerated() {
      
      
      
      
      if let cor = item["location"] as? NSDictionary {
        
        
        let font = UIFont.systemFont(ofSize: 16)
        let text = item["name"]
        let textWidth = 130.0
        let textHeight = heightForText(text as! String, withFont: font, width: textWidth)
        
        
        let options = ViewAnnotationOptions(
          geometry: Point(CLLocationCoordinate2D(latitude: cor["lat"] as! CLLocationDegrees, longitude: cor["lon"] as! CLLocationDegrees)),
          width: textWidth,
          height: textHeight+50,
          allowOverlap: true,
          visible: true,
          anchor: .center,
          offsetY: 0
          
        )
        
        let pointAnnotationManager = navViewController?.navigationMapView!.mapView.viewAnnotations
        // for item in pointAnnotationManager {
        if  let view = pointAnnotationManager?.view(forId: item["deviceId"] as! String){
          
          do {
            
            try pointAnnotationManager!.update(view, options: options)
            
          }  catch {
            print("An unexpected error occurred: \(error)")
          }
          
          
        }
        
        else {
          
          
          
          let (bgcolor,fgcolor) = getMapTextColor(mapView: mapView)
          
          
          let markerImage = "stopPoint"
          
          let sampleView = createLiveLocationView(withName:text as! String ,width: textWidth,height: textHeight,backgroundColor: bgcolor,forgroundColor: fgcolor, profileUrl: item["profile"] as! String)
          if isPreview {
            try? self.mapView?.mapView.viewAnnotations.add(sampleView,id:(item["deviceId"] as! String), options: options)
          }
          else {
            try? navViewController?.navigationMapView?.mapView.viewAnnotations.add(sampleView,id:(item["deviceId"]as! String), options: options)
          }
          
          
          
          
          
          
          
          
          
        }
        
      }
      
      
      
    }
    
    
    
    
  }
  
  // MARK: - Check Mapbox map theme
  
  
  func getMapTextColor(mapView:NavigationMapView) -> (UIColor,UIColor){
    
    var bgcolor = UIColor.white
    var fgcolor =  UIColor(red: 41/256, green: 42/256, blue: 47/256, alpha: 1)
    
    
    if let styleURL =  mapView.mapView.mapboxMap.style.uri {
      if (styleURL == StyleURI.dark) || (styleURL == StyleURI.navigationNight) {
        
        fgcolor = UIColor.white
        bgcolor = UIColor(red: 41/256, green: 42/256, blue: 47/256, alpha: 1)
      }
      
      
      
    }
    
    return(bgcolor,fgcolor)
    
  }
  
  
  
  
  func calculateTextWidth(text: String, font: UIFont) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
    let textSize = (text as NSString).size(withAttributes: attributes)
    
    return textSize.width
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
  
  // MARK: - Polyline Styling Methods
  
  func lineWidthExpression(_ multiplier: Double = 1) -> MapboxMaps.Expression {
    let lineWidthExpression = MapboxMaps.Expression(.interpolate) {
      MapboxMaps.Expression(.linear)
      MapboxMaps.Expression(.zoom)
      
      RouteLineWidthByZoomLevel.multiplied(by: multiplier)
    }
    
    return lineWidthExpression
  }
  
  // MARK: -Custom Driver Markers
  private func createLiveLocationView(withName text: String,width:CGFloat,height:CGFloat,backgroundColor:UIColor,forgroundColor:UIColor,profileUrl:String) -> UIView {
    
    
    let view = UIView()
    
    
    
    
    
    let markerLbl = UILabel(frame: CGRect(x:(width-40)/2 , y: 0, width: 40, height: 40))
    markerLbl.backgroundColor = .white
    markerLbl.textAlignment = .center
    markerLbl.font = .systemFont(ofSize: 16, weight: .bold)
    
    markerLbl.layer.cornerRadius = 20
    
    
    
    markerLbl.text = text.initials()
    
    markerLbl.textColor = forgroundColor
    
    // Enable masksToBounds to ensure the rounded corners are applied
    markerLbl.layer.masksToBounds = true
    
    view.addSubview(markerLbl)
    
    markerLbl.layer.cornerRadius = markerLbl.frame.size.width / 2
    markerLbl.clipsToBounds = true // Ensure the corners are clipped
    markerLbl.backgroundColor = UIColor.random()
    
    // Set the border
    markerLbl.layer.borderWidth = 1.0
    
    markerLbl.layer.borderColor =  forgroundColor.cgColor
    
    let imageView = UIImageView()
    imageView.frame = markerLbl.frame
    imageView.center.x = markerLbl.center.x
    
    imageView.layer.cornerRadius = markerLbl.frame.size.width / 2
    imageView.clipsToBounds = true // Ensure the corners are clipped
    imageView.layer.borderWidth = 1.0
    imageView.contentMode = .scaleToFill
    
    imageView.layer.borderColor =  forgroundColor.cgColor
    imageView.loadImage(from: profileUrl)
    
    view.addSubview(imageView)
    
    
    let lbl = UILabel(frame:CGRectMake(0, 40, width, height))
    lbl.text = text
    lbl.textAlignment = .center
    lbl.font = .systemFont(ofSize: 12, weight: .medium)
    lbl.textColor = forgroundColor
    lbl.numberOfLines = 0
    lbl.sizeToFit()
    lbl.center.x = markerLbl.center.x
    view.addSubview(lbl)
    
    
    
    
    
    
    
    return view
    
    
    
    
  }
  
  
  // MARK: -Custom Stop Markers
  
  
  private func createSampleView(withText text: String,width:CGFloat?,height:CGFloat?,markerText:String,markerImageName:String,bgc:UIColor,fgc:UIColor) -> UIView {
    
    
    if isPreview {
      let view = UIView()
      // view.backgroundColor = .white
      
      let markerImage = UIImageView(frame: CGRectMake((width!-30)/2, 2, 30, 30))
      //markerImage.image = waypointMarker
      
      markerImage.contentMode = .scaleAspectFit
      markerImage.image = UIImage(named: "\(markerImageName).png")
      
      let lbl = UILabel(frame: CGRect(x: 0, y: 32, width: width!, height: height!))
      lbl.text = text
      lbl.numberOfLines = 0
      lbl.textColor = .gray
      lbl.textAlignment = .center
      lbl.textColor = fgc
      
      lbl.font = UIFont.systemFont(ofSize: 14)
      view.addSubview(lbl)
      
      
      view.addSubview(markerImage)
      
      
      return view
      
    }
    
    
    let view = UIView()
    
    let markerImage = UIImageView(frame: CGRectMake((width!-30)/2, 0, 30, 30))
    //markerImage.image = waypointMarker
    
    markerImage.contentMode = .scaleAspectFit
    markerImage.image = UIImage(named: "\(markerImageName).png")
    
    
    view.addSubview(markerImage)
    
    
    let label = UILabel(frame: CGRect(x: 0, y: 30, width: width!, height: height!))
    
    label.text = text
    label.font = .systemFont(ofSize: 16, weight: .medium)
    label.numberOfLines = 0
    label.textColor = fgc
    
    label.textAlignment = .center
    
    view.addSubview(label)
    return view
    
    
    //return label
    
  }
  
  // MARK: - Styling marker methods
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
  
  
  // MARK: - Anootion delegates
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
  
  
  // MARK: - Route data source
  func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool{
    // return fals if rerouting is supposed to stop
    return true
  }
  
  // MARK: - Polyline Styling delegates
  
  func navigationMapView(_ navigationMapView: NavigationMapView, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
    var lineLayer = LineLayer(id: identifier)
    lineLayer.source = sourceIdentifier
    
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
  
  
  
  
  
  func navigationMapView(_ navigationMapView: NavigationMapView,
                         didAdd finalDestinationAnnotation: PointAnnotation,
                         pointAnnotationManager: PointAnnotationManager) {
    
    
    
    
    var finalDestinationAnnotation = finalDestinationAnnotation
    finalDestinationAnnotation.image = .init(image: UIImage(), name: "marker")
    
    pointAnnotationManager.annotations = [finalDestinationAnnotation]
    //  pointAnnotationManager.delegate = self
    
    
    
    
    self.addStopMarker(data: self.stops, mapView: navigationMapView)
    
    
  }
  
  
  
  
  // MARK: - Location delegate
  
  func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
    
    
    // call backs to native
    
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
  
  func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
    onArrive?(["message": ""]);
    
    return true;
  }
  
  // MARK: -Map Actions
  // press X button
  func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
    if (!canceled) {
      return;
    }
    onCancelNavigation?(["message": ""]);
  }
  
  
  
  
}
extension UIImageView {
  
  func loadImage(from url: URL) {
    // Create a background task to download the image
    DispatchQueue.global().async { [weak self] in
      // Fetch the image data from the URL
      if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
        DispatchQueue.main.async {
          // Update the UIImageView with the downloaded image on the main thread
          self?.image = image
        }
      }
    }
  }
  
  func loadImage(from urlString: String) {
    // Convert the string URL into a URL object
    if let url = URL(string: urlString) {
      loadImage(from: url)
    }
  }
}

extension UIColor {
  static func random() -> UIColor {
    return UIColor(
      red: CGFloat(arc4random_uniform(256)) / 255.0,
      green: CGFloat(arc4random_uniform(256)) / 255.0,
      blue: CGFloat(arc4random_uniform(256)) / 255.0,
      alpha: 1.0
    )
  }
}

extension String {
  func initials() -> String {
    // Split the string by spaces
    let words = self.components(separatedBy: " ")
    
    // Map each word to its first letter and join them
    let initials = words.compactMap { $0.first?.uppercased() }.joined()
    
    return initials
  }
}
