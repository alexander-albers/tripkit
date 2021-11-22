//

import Foundation

/// load factor tells the expected train capacity utilisation of a train of the DB provider
/// https://www.bahn.de/p/view/service/buchung/auslastungsinformation.shtml
public enum LoadFactor: Int {
    case low = 1, medium, high, exceptional
}
