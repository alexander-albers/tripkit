import Foundation

class LineDestination: NSObject {
    
    var line: Line
    var destination: Location?
    
    init(line: Line, destination: Location?) {
        self.line = line
        self.destination = destination
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? LineDestination else { return false }
        if object.line != line { return false }
        
        return destination?.getUniqueShortName() == object.destination?.getUniqueShortName()
    }
    
    override var hash: Int {
        if let destination = destination {
            return ((line.id ?? line.label ?? "") + destination.getUniqueShortName()).hash
        } else {
            return line.hash
        }
    }
    
    
}
