/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ARSCNViewDelegate interactions for `ViewController`.
*/

import ARKit
// HOOHACKS
import MapKit
// HOOHACKS

extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        let isAnyObjectInView = virtualObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        DispatchQueue.main.async {
            self.virtualObjectInteraction.updateObjectToCurrentTrackingPosition()
            self.updateFocusSquare(isObjectVisible: isAnyObjectInView)
        }
        
        // If light estimation is enabled, update the intensity of the directional lights
        if let lightEstimate = session.currentFrame?.lightEstimate {
            sceneView.updateDirectionalLighting(intensity: lightEstimate.ambientIntensity, queue: updateQueue)
        } else {
            sceneView.updateDirectionalLighting(intensity: 1000, queue: updateQueue)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusViewController.cancelScheduledMessage(for: .planeEstimation)
            self.statusViewController.showMessage("TAP SQUARE TO PLACE MAP")
        }
        updateQueue.async {
            for object in self.virtualObjectLoader.loadedObjects {
                object.adjustOntoPlaneAnchor(planeAnchor, using: node)
            }
        }
    }
    
    // HOOHACKS
    func addMap(_ result: ARHitTestResult) {
        guard noMap else { return }
        let planeAnchor = result.anchor as! ARPlaneAnchor
        let sideLength = CGFloat(max(planeAnchor.extent.x, planeAnchor.extent.z))
        let geo = SCNBox(width: sideLength, height: 0.02, length: sideLength,
                         chamferRadius: 0.01)
        geo.firstMaterial?.diffuse.contents = controller.view
        let node = SCNNode(geometry: geo)
        let pos = result.worldTransform.columns.3
        node.position = SCNVector3(pos.x, pos.y + 0.02, pos.z)
        mapNode = node
        sceneView.scene.rootNode.addChildNode(node)
        let alert = UIAlertController(title: "Enable Cloud Share?",
                                      message: "This will allow others to see the same map as you do.",
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Room ID"
        }
        alert.addAction(UIAlertAction(title: "No Thanks", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let gID = alert.textFields?.first?.text ?? UUID().uuidString
            self.startGroup(withID: gID, using: planeAnchor)
        })
        present(alert, animated: true)
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        guard UIEventSubtype.motionShake == motion, noMap else { return }
        let alert = UIAlertController.init(title: "Join A Group?",
                                           message: "This will allow you to join another person's map",
                                           preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Room ID"
        }
        alert.addAction(UIAlertAction(title: "No Thanks", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Join", style: .default) { [weak self] _ in
            guard let self = self, let gID = alert.textFields?.first?.text, !gID.isEmpty else { return }
            self.joinGroup(withID: gID)
        })
        present(alert, animated: true)
    }
    // HOOHACKS
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        updateQueue.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                for object in self.virtualObjectLoader.loadedObjects {
                    object.adjustOntoPlaneAnchor(planeAnchor, using: node)
                }
            } else {
                if let objectAtAnchor = self.virtualObjectLoader.loadedObjects.first(where: { $0.anchor == anchor }) {
                    objectAtAnchor.simdPosition = anchor.transform.translation
                    objectAtAnchor.anchor = anchor
                }
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
            
            // Unhide content after successful relocalization.
            virtualObjectLoader.loadedObjects.forEach { $0.isHidden = false }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Hide content before going into the background.
        virtualObjectLoader.loadedObjects.forEach { $0.isHidden = true }
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        /*
         Allow the session to attempt to resume after an interruption.
         This process may not succeed, so the app must be prepared
         to reset the session if the relocalizing status continues
         for a long time -- see `escalateFeedback` in `StatusViewController`.
         */
        return true
    }
}
