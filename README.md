# Flutter WebRTC Video Calling App

A fully-featured WebRTC video calling application built with Flutter for iOS and Android platforms.

## Features

- 📹 **Video Calling**: High-quality peer-to-peer video calls
- 🎤 **Audio Support**: Clear audio communication
- 🔇 **Mute Control**: Toggle microphone on/off during calls
- 📹 **Video Toggle**: Enable/disable video during calls
- 🔄 **Camera Switch**: Switch between front and rear cameras
- 📱 **Cross-Platform**: Works on both iOS and Android
- 📞 **Incoming Call UI**: Accept/Reject dialog for incoming calls
- 🔔 **Push Notifications**: Firebase Cloud Messaging for background calls
- 🆔 **Short IDs**: Easy-to-use 2-digit user IDs (11, 12, etc.)

## Architecture

The app is built using:
- **flutter_webrtc**: WebRTC implementation for Flutter
- **socket_io_client**: Real-time signaling communication
- **provider**: State management
- **permission_handler**: Camera and microphone permissions
- **flutter_local_notifications**: Local notifications
- **firebase_messaging**: Push notifications for background calls (optional)

## ⚠️ Important: Background Calling

**When app is OPEN or MINIMIZED**: ✅ Calls work perfectly via Socket.IO

**When app is COMPLETELY CLOSED**: ❌ Requires Firebase Cloud Messaging

For calls to work when app is fully closed, you need to setup Firebase FCM.
See detailed instructions in: **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)**

## Project Structure

```
lib/
├── models/
│   └── call_state.dart          # Call state enum
├── providers/
│   └── call_provider.dart       # State management for calls
├── screens/
│   ├── home_screen.dart         # Home screen with call initiation
│   └── call_screen.dart         # Active call interface
├── services/
│   └── signaling_service.dart   # WebRTC signaling logic
└── main.dart                    # App entry point
```

## Setup

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- iOS development: Xcode and CocoaPods
- Android development: Android Studio and Android SDK
- Node.js (for signaling server)

### Installation

1. **Clone or navigate to the project**
   ```bash
   cd c:\Users\solda\call
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up the signaling server**
   ```bash
   cd server
   npm install
   ```

### Running the Signaling Server

The app requires a signaling server to establish WebRTC connections.

```bash
cd server
npm install
npm start
```

Or run the server from the root:
```bash
node signaling_server.js
```

The server will start on `http://localhost:3000` by default.

## Running the App

### iOS

```bash
flutter run -d ios
```

**Note**: Make sure to have a physical device or simulator set up. Camera/microphone access requires physical device testing.

### Android

```bash
flutter run -d android
```

## Usage

1. **Start the signaling server** on your computer or deploy it to a cloud service
2. **Update the server URL** in the app (default: `http://localhost:3000`)
3. **Launch the app** on two devices
4. **Note the socket ID** from the console/logs on one device
5. **Enter the target socket ID** on the other device
6. **Press "Start Video Call"** to initiate the call

### During a Call

- **Mute/Unmute**: Tap the microphone icon
- **Toggle Video**: Tap the camera icon
- **Switch Camera**: Tap the camera switch icon
- **End Call**: Tap the red phone icon

## Permissions

### iOS (Info.plist)
- `NSCameraUsageDescription`: Camera access for video calls
- `NSMicrophoneUsageDescription`: Microphone access for audio calls

### Android (AndroidManifest.xml)
- `CAMERA`: Video capture
- `RECORD_AUDIO`: Audio recording
- `INTERNET`: Network communication
- `ACCESS_NETWORK_STATE`: Network state monitoring
- `MODIFY_AUDIO_SETTINGS`: Audio settings control

## Configuration

### Changing Signaling Server URL

Edit the default server URL in `lib/screens/home_screen.dart`:

```dart
final TextEditingController _serverController = TextEditingController(
  text: 'http://your-server-url:3000',
);
```

### STUN/TURN Servers

Modify ICE servers in `lib/services/signaling_service.dart`:

```dart
final Map<String, dynamic> configuration = {
  'iceServers': [
    {
      'urls': [
        'stun:stun1.l.google.com:19302',
        'stun:stun2.l.google.com:19302'
      ]
    }
  ]
};
```

For production, consider adding TURN servers for better connectivity.

## Deployment

### Deploying Signaling Server

You can deploy the signaling server to:
- **Heroku**: `git push heroku main`
- **AWS**: EC2 or Elastic Beanstalk
- **Google Cloud**: App Engine or Cloud Run
- **DigitalOcean**: Droplet

### Building the App

**iOS**:
```bash
flutter build ios --release
```

**Android**:
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

## Troubleshooting

### Connection Issues
- Ensure the signaling server is running and accessible
- Check firewall settings
- Verify the server URL is correct

### No Video/Audio
- Grant camera and microphone permissions
- Check device compatibility
- Test on physical devices (emulators may have limited support)

### ICE Connection Failed
- Add TURN servers for NAT traversal
- Check network connectivity
- Verify STUN/TURN server accessibility

## Based on Popular Solutions

This implementation is inspired by popular WebRTC solutions on GitHub, including:
- flutter_webrtc examples
- Socket.io signaling patterns
- Common WebRTC best practices

## License

This project is open source and available for educational and commercial use.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Flutter WebRTC documentation: https://github.com/flutter-webrtc/flutter-webrtc
3. Check Socket.io documentation: https://socket.io/

## Next Steps

- Implement user authentication
- Add chat messaging
- Support group calls
- Add call history
- Implement screen sharing
- Add call recording
- Enhance UI/UX with animations

---

Built with ❤️ using Flutter and WebRTC
