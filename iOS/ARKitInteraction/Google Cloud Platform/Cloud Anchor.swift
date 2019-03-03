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

extension ViewController {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        safely { try CloudAnchorManager.default.session.update(frame) }
    }
    
    func startGroup(withID gID: String, using anchor: ARPlaneAnchor) {
        do {
            let hosted = try CloudAnchorManager.default.session.hostCloudAnchor(anchor)
            db.child("hotspot_list").child(gID).child("hosted_anchor_id").setValue(hosted.cloudIdentifier)
        } catch {
            debugPrint(error)
        }
    }
    
    func joinGroup(withID gID: String) {
        db.child("hotspot_list").child(gID).observe(DataEventType.value, with: { [weak self] snapshot in
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                    let dict = snapshot.value as? [String: String],
                    let id = dict["hosted_anchor_id"]
                    else { return debugPrint("No anchor id") }
                do {
                    let anchor = try CloudAnchorManager.default.session
                        .resolveCloudAnchor(withIdentifier: id)
                    db.child("hotspot_list").child(gID).removeAllObservers()
                    let planeAnchor = ARPlaneAnchor(anchor: ARAnchor(transform: anchor.transform))
                    self.sceneView.session.add(anchor: planeAnchor)
                    self.addMap(planeAnchor)
                } catch {
                    debugPrint(error)
                }
            }
        })
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

extension CloudAnchorManager: GARSessionDelegate {
    /*
    -(void)session:(ARSession *)arSession didUpdateFrame:(ARFrame *)arFrame {
    [...]
    
    -(void)session:(GARSession *)garSession didHostAnchor:(GARAnchor *)garAnchor {
    // successful host
    }
    
    -(void)session:(GARSession *)garSession didFailToHostAnchor:(GARAnchor *)garAnchor {
    // failed host
    }
    
    -(void)session:(GARSession *)garSession didResolveAnchor:(GARAnchor *)garAnchor {
    // successful resolve
    }
    
    -(void)session:(GARSession *)garSession didFailToResolveAnchor:(GARAnchor *)garAnchor {
    // failed resolve
    }
    */
}
