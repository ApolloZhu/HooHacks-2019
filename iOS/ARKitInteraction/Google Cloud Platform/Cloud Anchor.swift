//
//  Cloud Anchor.swift
//  ARKitInteraction
//
//  Created by Apollo Zhu on 3/3/19.
//  Copyright © 2019 <script>alert("Who Hacks?")</script>. All rights reserved.
//

import UIKit
import Foundation
import ARCore
import Firebase

let db = Database.database().reference()

extension CloudAnchorManager {
    public static let `default` = try! CloudAnchorManager(session: GARSession(
        apiKey: "AIzaSyBkMTw83P7hUfuFvVuMQcftX1p8QWzFxF4",
        bundleIdentifier: nil
    ))
}

@discardableResult
func safely<T>(execute function: () throws -> T) -> T? {
    do {
        return try function()
    } catch {
        debugPrint(error)
        return nil
    }
}

extension ViewController: GARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        safely { try CloudAnchorManager.default.session.update(frame) }
    }
    
    func startGroup(withID gID: String, using anchor: ARPlaneAnchor) {
        do {
            self.gID = gID
             CloudAnchorManager.default.session.delegate = self
            _ = try CloudAnchorManager.default.session.hostCloudAnchor(anchor)
        } catch {
            debugPrint(error)
        }
    }
    
    func session(_ session: GARSession, didHostAnchor anchor: GARAnchor) {
        db.child("hotspot_list").child(gID).child("hosted_anchor_id").setValue(anchor.cloudIdentifier!)
        CloudAnchorManager.default.session.delegate = nil
    }
    
    func session(_ session: GARSession, didFailToHostAnchor anchor: GARAnchor) {
        debugPrint("Host \(anchor) Failed")
        CloudAnchorManager.default.session.delegate = nil
    }
    
    func joinGroup(withID gID: String) {
        db.child("hotspot_list").child(gID).observe(DataEventType.value, with: { [weak self] snapshot in
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                    let dict = snapshot.value as? [String: String],
                    let id = dict["hosted_anchor_id"]
                    else { return debugPrint("No anchor id") }
                do {
                    CloudAnchorManager.default.session.delegate = self
                    _ = try CloudAnchorManager.default.session
                        .resolveCloudAnchor(withIdentifier: id)
                } catch {
                    debugPrint(error)
                }
            }
        })
    }
    
    func session(_ session: GARSession, didResolve anchor: GARAnchor) {
        db.child("hotspot_list").child(gID).removeAllObservers()
        let planeAnchor = ARAnchor(transform: anchor.transform)
        sceneView.session.add(anchor: planeAnchor)
        #warning("addMap(planeAnchor)")
        CloudAnchorManager.default.session.delegate = nil
    }
    
    func session(_ session: GARSession, didFailToResolve anchor: GARAnchor) {
        debugPrint("Resolve \(anchor) Failed")
        CloudAnchorManager.default.session.delegate = nil
    }
}

// MARK: - Definition

public class CloudAnchorManager: NSObject {
    public let session: GARSession
    public init(session: GARSession) {
        self.session = session
        super.init()
    }
}
