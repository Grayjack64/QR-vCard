# Deployment Guide for Prosper Show QR vCard App

This guide provides instructions for deploying the Prosper Show QR vCard app to mobile devices.

## Option 1: Deploy as a Progressive Web App (PWA)

This is the recommended approach for your use case since it avoids app store distribution and works cross-platform.

### Step 1: Build the Web App

```bash
flutter build web
```

This will create a production build in the `build/web` directory.

### Step 2: Deploy to a Web Hosting Service

You have several options:

#### Firebase Hosting (Recommended)

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

#### Alternative Hosting Options

- **Netlify**: Upload the `build/web` directory or connect to your GitHub repository
- **GitHub Pages**: Upload the `build/web` directory to a GitHub repository and enable GitHub Pages
- **Amazon S3 + CloudFront**: For a more scalable solution

### Step 3: Access on Mobile Devices

1. Share the URL with attendees at the Prosper Show
2. For the best experience, users should add the PWA to their home screen:
   - **iOS (Safari)**: Tap the share icon, then "Add to Home Screen"
   - **Android (Chrome)**: Tap the menu icon, then "Add to Home Screen" or "Install App"

3. Create a QR code for the URL to make it easy for attendees to access the app

## Option 2: Build Native Apps (If PWA doesn't meet your needs)

If you need more native functionality or offline capabilities:

### For Android:

1. Build the APK:
   ```
   flutter build apk
   ```

2. The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

3. Distribute the APK directly to users (via email, download link, or USB transfer)

### For iOS:

1. Build the IPA (requires a Mac with Xcode):
   ```
   flutter build ios
   ```

2. Open the generated Xcode project:
   ```
   open ios/Runner.xcworkspace
   ```

3. In Xcode, use "Product > Archive" to create an archive

4. Use Ad Hoc distribution with registered device UDIDs to distribute without the App Store

## Recommended Approach for Prosper Show

For a trade show environment, the PWA approach (Option 1) is ideal because:

1. No app store approval required
2. Works on both iOS and Android
3. Easy to update (just redeploy the web app)
4. Simple distribution via URL/QR code
5. Can be added to home screen for app-like experience

## Testing Before Deployment

Before deploying, test the app thoroughly:

1. Test on different devices and browsers
2. Verify QR code generation and scanning works
3. Check that the app works offline after being added to home screen
4. Test saving and sharing QR codes

## Support at the Event

Prepare some quick instructions for attendees:
1. How to access the app (URL or QR code)
2. How to add to home screen
3. How to create and scan QR codes
4. Basic troubleshooting tips 