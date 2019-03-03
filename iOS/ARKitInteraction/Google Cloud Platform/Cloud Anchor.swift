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

let db = Firestore.firestore()

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
    
    func host(_ anchor: ARAnchor) -> GARAnchor? {
        return safely { try CloudAnchorManager.default.session.hostCloudAnchor(anchor) }
    }
    
    func retreiveCloudAnchor(withID id: String) -> GARAnchor? {
        return safely { try CloudAnchorManager.default.session
            .resolveCloudAnchor(withIdentifier: id) }
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
