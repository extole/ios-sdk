import Foundation
import SwiftUI

public class ExtoleObservableUi: ObservableObject {
    @Published var bodyContent: AnyView = AnyView(VStack {
        Text("")
    })
}
