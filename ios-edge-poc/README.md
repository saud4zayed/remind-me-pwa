# REMIND ME Edge Proof — native Swift research

We test whether VideoCall PiP can receive CUSTOM touch events while floating over normal iPhone Home and other apps. This is not a production reminder application.

1. Install a correctly signed build on a normal physical iPhone.
2. Interact with the embedded panel inside the app: IN APP SWIPE/BUTTON/EXPAND events must appear.
3. Press START PiP, return Home, and try swiping/tapping the floating content.
4. Return to the app and inspect event logs. PIP SWIPE/BUTTON/EXPAND events are the only proof of custom interaction; moving/stashing the PiP window is not.
5. Record model, iOS version, PiP start failure and logs.

Voice recording, reminders and confirmation are simulated. The objective is to prove or falsify a necessary prerequisite, not to falsely claim completed functionality.

Apple explicitly says VideoCall PiP content does not receive touch events or input:
https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller/contentsource-swift.class/activevideocallcontentviewcontroller

PiP is intended for video calls. This experimental app is NOT an App Store distribution recommendation:
https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-for-video-calls

## Build without local Mac
GitHub Actions compiles the project on a hosted macOS runner using XcodeGen. The build artifact is an UNSIGNED SIMULATOR app, not installable on physical iPhone. To test Home screen, Apple signing and a physical iPhone build are still required. Signing keys must never be committed in a public repository.

The code is isolated on branch edge-poc and does not modify the Cloudflare PWA or its main branch.
