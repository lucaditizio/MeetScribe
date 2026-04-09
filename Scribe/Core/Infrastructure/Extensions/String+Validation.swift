import Foundation

extension String {
    /// Checks if string is nil or empty (for use with Optional<String>)
    var isEmptyOrNil: Bool {
        return self.isEmpty
    }
    
    /// Validates if string is suitable for filename
    var isValidFilename: Bool {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|:\"<>")
        return self.rangeOfCharacter(from: invalidCharacters) == nil && !self.isEmpty
    }
    
    /// Truncates string to specified length with ellipsis
    func truncated(to length: Int) -> String {
        if self.count > length {
            return String(self.prefix(length)) + "..."
        }
        return self
    }
}
