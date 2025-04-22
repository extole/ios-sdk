import Foundation
import SwiftUI
import Combine

public class ExtoleObservableUi: ObservableObject {
    @Published var bodyContent: AnyView = AnyView(VStack {
        Text("")
    })
}
