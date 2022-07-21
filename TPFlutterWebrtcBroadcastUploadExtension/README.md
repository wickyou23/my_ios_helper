# TPFlutterWebrtcBroadcastUploadExtension

- A Code Demo for screen sharing feature use FlutterWebRTC and Broadcast.

## Setup
- Create a broadcast upload extension app.
- Create an app group id for the container app and extension app (used to share data between the container app and extension app), and make sure the same for both.
- Add bundle id of the extension app and app group id into Info.plist of container app.

```
<key>RTCScreenSharingExtension</key>
<string><Bundle id of the extension app></string>
<key>RTCAppGroupIdentifier</key>
<string><App group id></string>
```
