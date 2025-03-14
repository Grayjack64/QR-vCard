# Prosper Show QR vCard App

A Progressive Web App (PWA) for generating and scanning vCard QR codes for the Prosper Show in Las Vegas.

## Features

- **Generate vCard QR Codes**: Create QR codes containing your contact information in vCard format.
- **Scan vCard QR Codes**: Scan QR codes to view and save contact information.
- **Share Contacts**: Easily share contact information with others.
- **Save QR Codes**: Save generated QR codes to your device's gallery.
- **Works Offline**: As a PWA, the app can work without an internet connection once installed.
- **Cross-Platform**: Works on iOS, Android, and desktop browsers.
- **No App Store Required**: Access via URL and add to home screen.

## Getting Started

### For Users

1. Visit the app URL on your mobile device.
2. For the best experience, add the app to your home screen:
   - **iOS (Safari)**: Tap the share icon, then "Add to Home Screen"
   - **Android (Chrome)**: Tap the menu icon, then "Add to Home Screen" or "Install App"
3. Generate your vCard QR code by entering your contact information.
4. Share your QR code with others at the Prosper Show.
5. Scan other attendees' QR codes to quickly save their contact information.

### For Developers

This project is built with Flutter and can be deployed as a PWA.

#### Prerequisites

- Flutter SDK (with web support enabled)
- Dart SDK

#### Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/qr_vcard_app.git
   ```

2. Navigate to the project directory:
   ```
   cd qr_vcard_app
   ```

3. Get dependencies:
   ```
   flutter pub get
   ```

4. Run the app in development mode:
   ```
   flutter run -d chrome
   ```

#### Building for Production

1. Build the web app:
   ```
   flutter build web
   ```

2. The output will be in the `build/web` directory.

3. Deploy to a web server or hosting service like Firebase Hosting, Netlify, or GitHub Pages.

## Deployment

### Firebase Hosting (Recommended)

1. Install Firebase CLI:
   ```
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```
   firebase login
   ```

3. Initialize Firebase in your project:
   ```
   firebase init hosting
   ```
   - Select your Firebase project
   - Specify `build/web` as your public directory
   - Configure as a single-page app: Yes
   - Set up automatic builds and deploys: No

4. Deploy to Firebase:
   ```
   firebase deploy
   ```

5. Your app will be available at `https://your-project-id.web.app`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Flutter
- Uses the qr_flutter package for QR code generation
- Uses the mobile_scanner package for QR code scanning
