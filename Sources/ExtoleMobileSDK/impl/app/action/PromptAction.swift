import ObjectMapper
import SwiftUI

public class PromptAction: Action {
    public static var type: ActionType = ActionType.PROMPT
    var message: String?

    @State var isShowing = true

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        extole.getLogger().error("PromptAction, event=\(event.eventName), message=\(message ?? "")")
        isShowing = true
        extole.observableUi.bodyContent = AnyView(ToastView(message ?? ""))
    }

    init(message: String) {
        super.init()
        self.message = message
    }

    override init() {
        super.init()
    }

    public func getMessage() -> String? {
        message
    }

    public override func getType() -> ActionType {
        ActionType.PROMPT
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        message <- map["message"]
    }
}

struct ToastView: View {

    @State private var showToast = true

    private let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        NavigationView {
        }
            .toast(message: message, isShowing: $showToast, duration: Toast.short)
    }
}

struct Toast: ViewModifier {
    static let short: TimeInterval = 2
    static let long: TimeInterval = 3.5

    let message: String
    @Binding var isShowing: Bool
    let config: Config

    func body(content: Content) -> some View {
        ZStack {
            content
            toastView
        }
    }

    private var toastView: some View {
        VStack {
            Spacer()
            if isShowing {
                Group {
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(config.textColor)
                        .font(config.font)
                        .padding(8)
                }
                    .background(config.backgroundColor)
                    .cornerRadius(8)
                    .onTapGesture {
                        isShowing = false
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
                            isShowing = false
                        }
                    }
            }
        }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .animation(config.animation, value: isShowing)
            .transition(config.transition)
    }

    struct Config {
        let textColor: Color
        let font: Font
        let backgroundColor: Color
        let duration: TimeInterval
        let transition: AnyTransition
        let animation: Animation

        init(textColor: Color = .white,
             font: Font = .system(size: 14),
             backgroundColor: Color = .black.opacity(0.588),
             duration: TimeInterval = Toast.short,
             transition: AnyTransition = .opacity,
             animation: Animation = .linear(duration: 0.3)) {
            self.textColor = textColor
            self.font = font
            self.backgroundColor = backgroundColor
            self.duration = duration
            self.transition = transition
            self.animation = animation
        }
    }
}

extension View {
    func toast(message: String,
               isShowing: Binding<Bool>,
               config: Toast.Config) -> some View {
        self.modifier(Toast(message: message,
            isShowing: isShowing,
            config: config))
    }

    func toast(message: String,
               isShowing: Binding<Bool>,
               duration: TimeInterval) -> some View {
        self.modifier(Toast(message: message,
            isShowing: isShowing,
            config: .init(duration: duration)))
    }
}
