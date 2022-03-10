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

The Android application has an addition dependency on the
[ukey2](https://github.com/google/ukey2) project. There are several changes
that are required to build properly.

### Adding protoc dependency

Add the following block of code to the
[`build.gradle`](https://github.com/google/ukey2/blob/master/build.gradle) in
`ukey2`:

```
protobuf {
    protoc {
        artifact = 'com.google.protobuf:protoc:3.10.0'
    }
    generateProtoTasks {
        all().each { task ->
            task.builtins {
                java {
                    option "lite"
                }
            }
        }
    }
}
```

Alternatively, install `protoc` as described in
[Protocol Buffer Compiler Installation](https://grpc.io/docs/protoc-installation/).

### Fixing Google Truth dependency

The `ukey2` library depends on an older version of
[Google Truth](https://github.com/google/truth). This dependency needs to be
updated to at least `1.1.2`. Make the following change in the
[`build.gradle`](https://github.com/google/ukey2/blob/master/build.gradle):

```
compile group: 'com.google.truth.extensions', name: 'truth-java8-extension', version: '0.41'

# Change to
compile group: 'com.google.truth.extensions', name: 'truth-java8-extension', version: '1.1.2'
```
