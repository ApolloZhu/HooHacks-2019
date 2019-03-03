/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import ARKit
import SceneKit
import UIKit
// HOOHACKS
import MapKit
import CoreLocation
import FloatingPanel
// HOOHACKS

class ViewController: UIViewController {
    
    static var current: ViewController!
    let manager = CLLocationManager()
    var centerCoord: CLLocation?
    var noMap: Bool { return mapNode == nil }
    var mapNode: SCNNode?
    lazy var mapView: MKMapView = {
        return controller.view.subviews.first { $0 is MKMapView } as! MKMapView
    }()
    private(set) lazy var controller: UIViewController = {
        let controller = UIViewController()
        let mapView = MKMapView()
        mapView.mapType = .satelliteFlyover
        let center = self.centerCoord?.coordinate ??
            CLLocationCoordinate2D(latitude: 38.0315612, longitude: -78.5148471)
        mapView.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        controller.view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        ])
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(tapOnMap(_:)))
        mapView.addGestureRecognizer(tapRecognizer)
        return controller
    }()
    
    private let geoCoder = CLGeocoder()
    
    @objc private func tapOnMap(_ recognizer: UITapGestureRecognizer) {
        let coordinate = mapView.convert(recognizer.location(in: mapView), toCoordinateFrom: mapView)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "en_US")) { (placemarks, error) in
            func isValid(_ placemark: String?) -> Bool {
                guard let placemark = placemark else { return false }
                return !placemark.isEmpty
            }
            guard let placemark = placemarks?.first(where: {
                return isValid($0.subThoroughfare)
                    && isValid($0.thoroughfare)
                    && isValid($0.locality)
                    && isValid($0.administrativeArea)
            }) else { return debugPrint(error ?? "Error Retriving Placemark") }
            let street = placemark.subThoroughfare! + " " + placemark.thoroughfare!
            HouseInfo.ofHouse(at: street, in: placemark.locality! + ", " + placemark.administrativeArea!) {
                [weak self] in self?.processHouse($0, at: street)
            }
        }
    }
    
    private func processHouse(_ house: HouseInfo?, at street: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            defer { self.fpc.move(to: .tip, animated: true) }
            let infoVC = self.fpc.contentViewController as! HouseInfoViewController
            infoVC.streetNameLabel.text = street
            if let house = house {
                infoVC.priceLabel.text = "$ \(house.zestimate.amount)"
                infoVC.areaLabel.text = "\(house.propertySize) ft²"
                infoVC.bathroomCountLabel.text = "\(house.bathroomsCount)"
                infoVC.bedroomCountLabel.text = "\(house.bedroomsCount)"
            } else {
                infoVC.priceLabel.text = "No Information Available"
                infoVC.areaLabel.text = ""
                infoVC.bathroomCountLabel.text = ""
                infoVC.bedroomCountLabel.text = ""
            }
            print(house)
        }
    }
    
    let fpc = FloatingPanelController()
    // HOOHACKS
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    // MARK: - UI Elements
    
    var focusSquare = FocusSquare()
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    deinit {
        fpc.removePanelFromParent(animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // HOOHACKS
        ViewController.current = self
        manager.delegate = self
        manager.startUpdatingLocation()
        
        fpc.delegate = self
        let contentVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "HouseInfoViewController")
            as! HouseInfoViewController
        fpc.set(contentViewController: contentVC)
        fpc.track(scrollView: contentVC.tableView)
        fpc.isRemovalInteractionEnabled = true
        fpc.addPanel(toParent: self)
        fpc.hide()
        // HOOHACKS
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Set up scene content.
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        sceneView.setupDirectionalLighting(queue: updateQueue)
        
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the `ARSession`.
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
    
    // MARK: - Scene content setup
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
    func resetTracking() {
        // HOOHACKS
        mapNode?.removeFromParentNode()
        mapNode = nil
        // HOOHACKS
        virtualObjectInteraction.selectedObject = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE THE MAP", inSeconds: 7.5, messageType: .planeEstimation)
    }
    
    // MARK: - Focus Square
    
    func updateFocusSquare(isObjectVisible: Bool) {
        if !noMap {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // Perform hit testing only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let result = self.sceneView.smartHitTest(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
            }
            statusViewController.cancelScheduledMessage(for: .focusSquare)
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
        }
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
}

// HOOHACKS
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.centerCoord = locations.last
    }
}
// HOOHACKS
