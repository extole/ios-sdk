# Extole iOS SDK

This app provides source code examples of how to:
- send an event to Extole
- get a resource (text, url, data) describing a marketing campaign configured in Extole
- share via email through Extole
- share using Android native share
- render a zone using WebView

Screenshot:

[<img src="https://user-images.githubusercontent.com/304224/141311440-f50063af-58f0-44b8-97ef-81d020a1045a.png" width="250">](https://user-images.githubusercontent.com/304224/141311440-f50063af-58f0-44b8-97ef-81d020a1045a.png)

## Setup

1. Clone this repository
2. Open it with XCode or AppCode
3. Run it in a simulator or real device

## Using the Extole iOS SDK

### Cocoapods

```
pod install extole-sdk
```

### Swift packages

```

```

### Initializing SDK
We recommend that you keep a reference to the `extole` and share it between activities.

Example from below uses `Observable` pattern from SwiftUI

Declare your ObservableObject:
```
class ExtoleProgram: ObservableObject {
    @Published var shareExperience = ExtoleShareExperience()
    let extole: ExtoleService = ExtoleService(programDomain: "https://di-test-client.extole.io",
        applicationName: "iOS App", labels: ["refer-a-friend"])

    func fetchExtoleProgram() {
        extole.getZone("apply_for_card") { (zone: ExtoleMobileSDK.Zone?, _: ExtoleMobileSDK.Campaign?, error: Error?) in
            if error != nil {
                self.shareExperience = ExtoleShareExperience(title: "Error",
                    shareButtonText: "...",
                    shareMessage: error?.localizedDescription ?? "Unable to load Extole Zone", shareImage: "...")
            } else {
                let shareImage = zone?.get("sharing.email.image") as! String? ?? ""
                let shareButtonText = zone?.get("sharing.email.subject") as! String? ?? ""
                let shareMessage = zone?.get("sharing.email.message") as! String? ?? ""
                self.shareExperience = ExtoleShareExperience(title: "Extole Sharing Program",
                    shareButtonText: shareButtonText,
                    shareMessage: shareMessage, shareImage: shareImage)
            }
        }
    }
}
```

When initializing your application, don't forget to pass `environmentObject`:

```
struct IOSApp: App {
    let extoleProgram = ExtoleProgram()
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environmentObject(extoleProgram)
        }
    }
}
```

### Using SwiftUI to create a View with Extole creative resources

Using this code we will obtain the view presented in the above screenshot
```
struct ContentView: View {
    @EnvironmentObject var extoleProgram: ExtoleProgram

    var body: some View {
        NavigationView {
            VStack {
                AsyncImage(url: URL(string: extoleProgram.shareExperience.shareImage))
                    .frame(height: 400)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 4))
                    .shadow(radius: 7)
                Text(extoleProgram.shareExperience.shareMessage)
                    .padding()
                Button(extoleProgram.shareExperience.shareButtonText, role: .destructive) {
                }
                    .padding()
                Spacer()
            }.task {
                extoleProgram.fetchExtoleProgram()
            }
        }
    }
}
```

### WebView example

A webview is a convenient way to support a rich campaign experience, while minimizing mobile development. Extole,
supports tracking important events in the webview, like tracking native sharing events.

```
UIExtoleWebView("https://program-domain.tld", "microsite", ["labels": "business", "email": "..."], ["header":"value"])
```

[<img src="https://user-images.githubusercontent.com/304224/141311425-3baeeda8-16be-41ae-8b05-10282bc58789.png" width="250">](https://user-images.githubusercontent.com/304224/141311425-3baeeda8-16be-41ae-8b05-10282bc58789.png)

### Sending events

```
extole.sendEvent("conversion", ["cart_value": "10.0"]) { (idEvent: Id<Event>?, error) in
    ...
}
```

### Sharing via Email through Extole

```
extole.getZone("promotional_email") { (zone, campaign, error) -> in
    campaign.emailShare(recipient, subject, message) { (idEvent, error) -> in
        ...
    }
}
```
