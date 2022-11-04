# Extole iOS SDK
This integration guide shows you how to set up and launch an Extole program as quickly as possible with our iOS SDK.

## Requirements
The Extole iOS SDK supports iOS 13.0 and later.


## Step 1: Add Cocoapods dependency

Add the `ExtoleMobileSDK` dependency to your Podfile:

```
pod 'ExtoleMobileSDK', '>= 0.0.29'
```

## Step 2: Initialize SDK

#### In your `AppDelegate` class, initialize Extole:

```
class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    ...
    @Published var extole: Extole = ExtoleImpl(programDomain: "<your-program-domain>")
    ...
}
```

_For a working example, please reference our [Github documentation](https://github.com/extole/ios/blob/master/iOSDemo/iOSDemo/ExtoleCampaign.swift)._
You’ll need to provide your Extole program domain. For more detailed configuration options, see the Advanced Usage section.


#### In your `main` method, pass Extole to your view:

```
@main
struct ExtoleApp: App {
    ...
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    ...
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(delegate.extole)
        }
    }
    ....
}
```

_For a working example, please reference our [Github documentation](https://github.com/extole/ios/blob/master/iOSDemo/iOSDemo/iOSDemoApp.swift)._

#### Initialize the `View` provided by Extole:
```
struct ContentView: View {
    ...
    @EnvironmentObject var extole: Extole
    ...
    var body: some View {
        NavigationView {
              extole.getView()         
        }
    }
    ...
}
```

By default, Extole will use this single view to interact with the customer.

#### Send Extole information about the customer:

```
extole.identify("email", ["partner_user_id": "123"], 
       {(eventId: Id<Event>?, error: Error?) in   
})
```

You can choose to pass any type of data to describe the customer. Richer data about your customers gives your marketing team the information they need to better segment your program participants and target them with appropriate campaigns.

#### Send Extole events, such as registers, signups, conversions, account openings, etc:

```
extole.sendEvent("signup", ["petname": "rover"]))
```

For each event type, you can send additional data. For example, on a conversion event you may want to pass in order ID or order value and so on.

#### Populate a call to action (CTA) with content from Extole.

CTAs such as mobile menu items can be fully customized in the My Extole Campaign Editor. Each CTA has a designated zone. The following code is an example of how to retrieve a CTA by fetching zone content:

```
extole.fetchZone("cta_prefetch") { (zone: ExtoleMobileSDK.Zone?, campaign: ExtoleMobileSDK.Campaign?, error: Error?) in
    let ctaImage = zone?.get("image") as! String? ?? ""
    let ctaText = zone?.get("text) as! String? ?? ""
    let ctaMessage = zone?.get("message") as! String? ?? ""
}

// usage example:
View {
    Text(extoleProgram.cta.ctaMessage)
}

// send the CTA event when the view is displayed
View {
       .... // your view    
    }.task {
        extoleProgram.fetchExtoleProgram()
        extole.sendEvent("cta")
   }
}

// on CTA tap send the event to Extole
View {
.... // your view    
}.onTapGesture {
    extole.sendEvent("cta_tap")
}

```
_For a working example, please reference our [Github documentation](https://github.com/extole/ios/blob/master/iOSDemo/iOSDemo/ContentView.swift)._
In order to be able to fetch the `cta` zone, the zone should be configured in My Extole and should return JSON content containing the `image`, `text,`and `message`.

Important note: We encourage you to pull CTA content from My Extole because doing so ensures that your menu item or overlay message will reflect the copy and offer you’ve configured for your campaign.

# Advanced Usage

The following topics cover advanced use cases for the Extole iOS SDK. If you would like to explore any of these options, please reach out to our Support Team at support@extole.com.

## Integrating with a Deeplink Provider
Completing a deep link integration is simple once you have integrated with a deep link provider, such as Branch. Send a mobile event to Extole, and based on the configuration of your mobile operations, our framework will execute the corresponding action.

Deep link example:

```
class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
   @Published var deeplinkProperties: [String: String] = [:]
   @Published var extole: Extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io",
       applicationName: "iOS App", labels: ["business"], listenToEvents: true)

   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

       Branch.getInstance().initSession(launchOptions: launchOptions) { [self] (params, _) in
           params?.forEach({ (key: AnyHashable, value: Any) in
               deeplinkProperties[key as! String] = String(describing: value)
           })
           extole.getLogger().debug("Deeplink data: \(deeplinkProperties)")
           extole.sendEvent("deeplink", deeplinkProperties) { _, _ in
           }
       }
       return true
   }
}
```

## Configuring Actions from Events
You can set up a specific action to occur when an event is fired. For example, when a customer taps on your menu item CTA, you may want the event to trigger an action that loads your microsite and shows the share experience.
To set up this type of configuration, you will need to work with Extole Support to set up a zone in My Extole that returns JSON configurations with conditions and actions. The SDK executes actions for conditions that are passing for a specific event:

```
{
  "operations": [
    {
      "conditions": [
        {
          "type": "EVENT",
          "event_names": [
            "cta_tap"
          ]
        }
      ],
      "actions": [
        {
          "type": "VIEW_FULLSCREEN",
          "zone_name": "microsite"
        }
      ]
    }
  ]
}
```



### Supported Actions
The following types of actions are supported by default in our SDK.
<table>
  <tr>
   <td><strong>Action Name</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td><code>PROMPT</code>
   </td>
   <td>Display a pop-up notification native to iOS. For example, this could appear when a discount or coupon code has been successfully applied. 
   </td>
  </tr>
  <tr>
   <td><code>NATIVE_SHARING</code>
   </td>
   <td>Open the native share sheet with a predefined message and link that customers can send via SMS or any enabled social apps. 
   </td>
  </tr>
  <tr>
   <td><code>VIEW_FULLSCREEN</code>
   </td>
   <td>Trigger a full screen mobile web view. For example, this could be your microsite as configured in My Extole to display the share experience.
   </td>
  </tr>
</table>



### Custom Actions

If you would like to create custom actions beyond our defaults, use the format exhibited in the example below. Please reach out to our Support Team at [support@extole.com](mailto:support@extole.com) if you have any questions.


#### Example custom action


```
import ExtoleMobileSDK

public class CustomAction: Action {
   public static var type: ActionType = ActionType.CUSTOM

   var customActionValue: String?

   public override func execute(event: AppEvent, extole: ExtoleImpl) {
       extole.getLogger().setLogLevel(level: LogLevel.disable)
   }

   init(customActionValue: String) {
       super.init()
       self.customActionValue = customActionValue
   }

   override init() {
       super.init()
   }

   public override func getType() -> ActionType {
       ActionType.CUSTOM
   }

   public required init?(map: Map) {
       super.init()
   }

   public override func mapping(map: Map) {
       customActionValue <- map["custom_action_value"]
   }

   public var description: String {
       return "CustomAction[customActionValue:\(customActionValue)]"
   }
}
```

#### Registering a custom action
```
Action.customActionTypes["CUSTOM_ACTION"] = CustomAction()
```


## Appendix
### Advanced Actions
#### Load Operations
```
{
  "type": "LOAD_OPERATIONS",
  "zones": [
    "<zone_name>"
  ],
  "data": {
    "key": "value"
  }
}
```



####  Fetch
```
{
  "type": "FETCH",
  "zones": [
    "<zone_name_1>",
    "<zone_name_2>"
  ]
}
```



#### Set Log Level
```
{
  "type": "SET_LOG_LEVEL",
  "log_level": "WARN"
}
```

