Firefox iOS without Telemetry!*
===============

Getting involved
----------------

If you remove more telemetry that I missed, or want to suggest something to be changed make a PR or issue!
Make sure to check the to-do below if you want to take up a task yourself.

Features
----
- Mozilla's "TelemetryWrapper" and all related calls removed.
- Tracking Protection forced to "strict", however options insist on "Standard" (https://github.com/haiku-balls/firefox-ios-noTelemetry/issues/1)
- Studies and SendUsage flags forced disabled.
- Pocket and sponsored tiles/pocket disabled.

Todo
----
- Remove the pinned Google tile.
- Remove the "Glean" telemetry service. (Might be too integrated; might not even phone home...?)

Building the code
-----------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install, [Brew](https://brew.sh), Node, and a Python3 virtualenv for localization scripts:
    ```shell
    brew update
    brew install node
    pip3 install virtualenv
    ```
1. Clone the repository:
    ```shell
    git clone https://github.com/haiku-balls/firefox-ios-noTelemetry/
    ```
1. Install Node.js dependencies, build user scripts and update content blocker:
    ```shell
    cd firefox-ios
    sh ./bootstrap.sh
    ```
1. Open `Client.xcodeproj` in Xcode.
1. Make sure to select the `Fennec` [scheme](https://developer.apple.com/documentation/xcode/build-system?changes=_2) in Xcode.
1. Select the destination device you want to build on.
1. Run the app with `Cmd + R` or by pressing the `build and run` button.

⚠️ Important: In case you have dependencies issues with SPM, please try the following:
- Xcode -> File -> Packages -> Reset Package Caches

License
-----------------

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/
