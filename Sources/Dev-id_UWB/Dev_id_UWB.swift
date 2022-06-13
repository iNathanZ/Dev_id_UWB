import Foundation
import MultipeerConnectivity
import os

@available(iOS 14.0, *)
public class Dev_id_UWB: NSObject, ObservableObject {

    public let serviceType = "uwb-session"
    public let session: MCSession
    public let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    public let serviceAdvertiser: MCNearbyServiceAdvertiser
    public let serviceBrowser: MCNearbyServiceBrowser
    public let log = Logger()
        
    @Published public var receivedMsg: String? = nil
    @Published public var inputMsg: String = ""
    @Published public var receivedImage: UIImage?
    @Published public var inputImage: UIImage?
    
    @Published public var connectedPeers: [MCPeerID] = []

    @Published public var selectedDevice: MCPeerID? = nil
    
    public override init() {
        precondition(Thread.isMainThread)
        self.session = MCSession(peer: myPeerId)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        super.init()

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self

        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    public func sendMessage(message: String) {
        precondition(Thread.isMainThread)
        if !session.connectedPeers.isEmpty {
            if let vSelectedDevice = selectedDevice {
                do {
                    try session.send(message.data(using: .utf8)!, toPeers: [vSelectedDevice], with: .reliable)
                } catch {
                    log.error("Error for sending: \(String(describing: error))")
                }
            }
        }
    }
    
    public func sendImage() {
        precondition(Thread.isMainThread)
        if !session.connectedPeers.isEmpty {
            if let vSelectedDevice = selectedDevice {
                let data = inputImage?.pngData()
                do {
                    try session.send(data!, toPeers: [vSelectedDevice], with: .reliable)
                } catch {
                    log.error("Error for sending: \(String(describing: error))")
                }
            }
        }
    }
    
    public func sendData(data: Data) {
        precondition(Thread.isMainThread)
        if !session.connectedPeers.isEmpty {
            if let vSelectedDevice = selectedDevice {
                do {
                    try session.send(data, toPeers: [vSelectedDevice], with: .reliable)
                } catch {
                    log.error("Error for sending: \(String(describing: error))")
                }
            }
        }
    }
    
}

@available(iOS 14.0, *)
extension Dev_id_UWB: MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
    }
}

@available(iOS 14.0, *)
extension Dev_id_UWB: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.debugDescription)")
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let string = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedMsg = string
            }
        }
        if let image = UIImage(data: data, scale: 1.0) {
            DispatchQueue.main.async {
                self.receivedImage = image
            }
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}

extension MCSessionState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notConnected:
            return "notConnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        @unknown default:
            return "\(rawValue)"
        }
    }
}

@available(iOS 14.0, *)
extension Dev_id_UWB: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        precondition(Thread.isMainThread)
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        precondition(Thread.isMainThread)
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }
}
