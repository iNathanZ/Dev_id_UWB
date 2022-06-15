//
//  PeerInformations.swift
//  
//
//  Created by Nathan Zerbib on 15/06/2022.
//

import Foundation
import UIKit

public struct PeerInformations: Codable {
    public var name: String
    public var profilePictureData: Data?
    
    public func getProfilePicture() -> UIImage? {
        if let vProfilePictureData = self.profilePictureData {
            let decoded = try! PropertyListDecoder().decode(Data.self, from: vProfilePictureData)
            return UIImage(data: decoded)
        }
        return nil
    }
    
}

public func getDataFromPeerInformations(infos: PeerInformations) -> Data? {
    do {
      let data = try PropertyListEncoder.init().encode(infos)
      return data
    } catch let error as NSError{
      print(error.localizedDescription)
    }
    return nil
}


public func getPeerInformationsFromData(data: Data) -> PeerInformations? {
    do {
      let packet = try PropertyListDecoder.init().decode(PeerInformations.self, from: data)
      return packet
    } catch let error as NSError{
      print(error.localizedDescription)
    }
    return nil
}
