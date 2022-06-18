import Foundation
import MultipeerConnectivity
import os
import NearbyInteraction
import Combine

@available(iOS 14.0, *)
public class Dev_id_UWB: NSObject, NISessionDelegate, ObservableObject {
    
    public var mpcClient: MPCClient?
    @Published var subscribedDict: [MCPeerID:PeerInformations] = [:]
    
    //UWB
    @Published public var niSession: NISession?
    @Published public var peerDiscoveryToken: NIDiscoveryToken?
    @Published public var sharedTokenWithPeer = false
    @Published public var distanceToSelected: Float?
    
    private var bag = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        mpcClient = MPCClient()
        mpcClient?.peerConnectedHandler = connectedToPeer
        mpcClient?.peerDataHandler = dataReceivedHandler
        mpcClient?.peerDisconnectedHandler = disconnectedFromPeer
        self.mpcClient?.$receivedMsg.compactMap({ $0 }).sink { [weak self ] value in
            if value == "START_NISESSION" {
                self?.startNISession()
            } else if value == "STOP_NISESSION" {
                self?.stopNISession()
            }
        }.store(in: &bag)
        mpcClient?.$peersDict.assign(to: \.subscribedDict, on: self).store(in: &bag)
    }
    
    public func stopNISession() {
        niSession = nil
        niSession?.delegate = nil
        sharedTokenWithPeer = false
        mpcClient?.selectedDevice = nil
    }
    
    public func sendStopMsgNISession() {
        mpcClient?.sendData(data: "STOP_NISESSION".data(using: .utf8)!, targetDevice: mpcClient?.selectedDevice)
    }
    
    public func shareMyDiscoveryToken(token: NIDiscoveryToken) {
        guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }
        if let vSelectedDevice = mpcClient?.selectedDevice {
            do {
                try mpcClient?.session.send(encodedData, toPeers: [vSelectedDevice], with: .reliable)
            } catch let error {
                NSLog("Error sending data: \(error)")
            }
            sharedTokenWithPeer = true
            self.peerDiscoveryToken = niSession?.discoveryToken
        }
    }

    func disconnectedFromPeer(peer: MCPeerID) {
        if mpcClient?.selectedDevice == peer {
            niSession = nil
            niSession?.delegate = nil
            sharedTokenWithPeer = false
            mpcClient?.selectedDevice = nil
        }
    }

    func dataReceivedHandler(data: Data, peer: MCPeerID) {
        guard let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            fatalError("Unexpectedly failed to decode discovery token.")
        }
        peerDidShareDiscoveryToken(peer: peer, token: discoveryToken)
    }
    
    func connectedToPeer(peer: MCPeerID) {
        guard let myToken = niSession?.discoveryToken else {
            fatalError("Unexpectedly failed to initialize nearby interaction session.")
        }

        if mpcClient?.selectedDevice != nil {
            fatalError("Already connected to a peer.")
        }

        if !sharedTokenWithPeer {
            shareMyDiscoveryToken(token: myToken)
        }

        mpcClient?.selectedDevice = peer
    }
    
    public func startNISession() {
        niSession = NISession()
        niSession?.delegate = self
        sharedTokenWithPeer = false
        
        if mpcClient?.selectedDevice != nil {
            if let myToken = niSession?.discoveryToken {
                print("Initializing")
                if !sharedTokenWithPeer {
                    shareMyDiscoveryToken(token: myToken)
                }
//                guard let peerToken = peerDiscoveryToken else {
//                    return
//                }
                let config = NINearbyPeerConfiguration(peerToken: (niSession?.discoveryToken!)!)
                niSession?.run(config)
            } else {
                fatalError("Unable to get self discovery token, is this session invalidated?")
            }
        }
    }
    
    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
        // Create a configuration.
        peerDiscoveryToken = token
        let config = NINearbyPeerConfiguration(peerToken: token)
        // Run the session.
        niSession = NISession()
        niSession?.delegate = self
        sharedTokenWithPeer = false
        niSession?.run(config)
    }
}

@available(iOS 14.0, *)
extension Dev_id_UWB: NISessionDelegate {
    public func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }

//        // Find the right peer.
//        let peerObj = nearbyObjects.first { (obj) -> Bool in
//            return obj.discoveryToken == peerToken
//        }
//
//        guard let nearbyObjectUpdate = peerObj else {
//            return
//        }
        
        self.distanceToSelected = nearbyObjects.first?.distance
    }
}
