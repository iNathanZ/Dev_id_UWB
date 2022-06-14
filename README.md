# Dev-id | Ultra WideBand Package

[![N|Solid](https://images.squarespace-cdn.com/content/v1/5fc52d89ea4a794d566102b9/9c074051-37b0-424f-abeb-a95dd9f4f085/logoDevidBlanc.png)](https://nodesource.com/products/nsolid)

This package is a built-in class allowing to create NearbyInteractions Sessions, to connect to them, and to exchange informations thanks to the U1 Chip.

## Installation
You just need to add this package with the Swift Package Manager.
File > Add package > Paste this [repository URL](https://github.com/iNathanZ/Dev_id_UWB)
Don't forget to add the local network capability.
Paste this code into the info.plist:
```
<key>NSLocalNetworkUsageDescription</key>
<string>Reason for using Bonjour that the user can understand</string>
<key>NSBonjourServices</key>
<array>
    <string>_uwb-session._tcp</string>
    <string>_uwb-session._udp</string>
</array>
```

## Uses

The Dev_id_UWB class initialization already creates the session.
Just call it as a `@StateObject var uwbSession: Dev_id_UWB = .init()` and you can use the functions and variables.

#### Variables
- `receivedMsg: String?` - A nullable string received from another device
- `inputMsg: String?` - A nullable string you send to another device
- `receivedImage: UIIMage?` A nullable image received from another device
- `inputImage: UIIMage?` A nullable image received from another device
- `connectedPeers: [MCPeerID]` - An array of connected devices
- `selectedDevice: MCPeedID?`- The device selected by the user

#### Functions
- `sendMessage(message: String)` - Send a message to the selected device
- `sendImage()` - Send the inputImage to the selected device
- `sendData(data: Data)` - Send a data to the selected device

## Development

Want to contribute? Great!
This package is still under development, feel free to contact me at nzerbib@dev-id.fr.
