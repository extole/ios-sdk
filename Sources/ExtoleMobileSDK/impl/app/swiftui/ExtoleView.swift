import Foundation
import SwiftUI

public struct ExtoleView: View {
    @ObservedObject var view: ExtoleObservableUi
    public var body: some View {
        view.bodyContent
    }
}
