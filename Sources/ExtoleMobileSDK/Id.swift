import Foundation

public class Id<Element> {
    let value: String

    init(_ element: String) {
        value = element
    }

    public func getValue() -> String {
        value
    }
}
