# Android Auto Companion Reference App

A demo application that showcases the functionality of the Android Auto
Companion Libraries. These libraries are available for both iOS and
Android under the following repositories:

- [Android](https://github.com/google/android-auto-companion-android)
- [iOS](https://github.com/google/android-auto-companion-ios)

## Getting Started

This application is built using Flutter. Refer to the
[official documentation](https://flutter.dev/docs) for how to set up your
environment for building Flutter.

## Building iOS

The project can be opened via `ios/Runner.xcworkspace`. Ensure that you have a
proper development team selected in XCode for the project.

Navigate into the `ios` directory and run the following to initialize the
Flutter environment:

```
flutter build ios
```

After this, the project should be buildable and deployable via XCode.

## Building Android

To set up the initial environment, navigate into the `android` directory and
run the following:

```
flutter build apk
```

After this, the project should be buildable and deployable via
[Android Studio](https://developer.android.com/studio).
