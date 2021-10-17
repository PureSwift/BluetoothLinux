//
//  Sequence.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

internal extension Sequence {
    
    @usableFromInline
    func _buildDescription() -> String {
        var string = "["
        for element in self {
            if _slowPath(string.count == 1) {
                string += "\(element)"
            } else {
                string += ", \(element)"
            }
        }
        string += "]"
        return string
    }
}
