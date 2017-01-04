import Foundation

internal extension String {
    func generatedClassName() -> String {
        if isEmpty { return "" }

        var generatedClassName = camelCased().depluralize()
        let replacementRange = (generatedClassName.startIndex ..< generatedClassName.index(after: generatedClassName.startIndex))
        let initial = generatedClassName.substring(with: replacementRange)
        generatedClassName.replaceSubrange(replacementRange, with: initial.uppercased())
        return generatedClassName
    }

    func depluralize() -> String {
        if isEmpty { return "" }

        let name = self
        if name.hasSuffix("uies") {
            return name.substring(to: name.index(name.endIndex, offsetBy: -4)).appending("y")
        }
        if name.hasSuffix("ices") {
            // fails for ix, eg: matrix
            return name.substring(to: name.index(name.endIndex, offsetBy: -4)).appending("ex")
        }
        if name.hasSuffix("eaux") || name.hasSuffix("eaus") {
            return name.substring(to: name.endIndex)
        }
        if name.hasSuffix("ves") {
            return name.substring(to: name.index(name.endIndex, offsetBy: -3)).appending("f")
        }
        if name.hasSuffix("ata") {
            return name.substring(to: name.index(name.endIndex, offsetBy: -3)).appending("ma")
        }
        if name.hasSuffix("mas") {
            return name.substring(to: name.index(before: name.endIndex))
        }
        if name.hasSuffix("ies") {
            // list of words not to change; series, species
            return name.substring(to: name.index(name.endIndex, offsetBy: -3)).appending("y")
        }
        if name.hasSuffix("ses") {
            return name.substring(to: name.index(name.endIndex, offsetBy: -3)).appending("is")
        }
        if name.hasSuffix("es") {
            if name == "houses" {
                return "house"
            }
            return name.substring(to: name.index(before: name.endIndex))
        }
        if name.hasSuffix("ae") {
            return name.substring(to: name.index(before: name.endIndex))
        }
        if name.hasSuffix("um") {
            return name.substring(to: name.endIndex).appending("a")
        }
        if name.hasSuffix("us") {
            // fails for eg: genus -> genera or corpus -> corpora, status
            return name.substring(to: name.index(before: name.endIndex)).appending("i")
        }
        if name.hasSuffix("en") {
            return name.substring(to: name.index(before: name.endIndex))
        }
        if name.hasSuffix("fs") {
            return name.substring(to: name.index(before: name.endIndex))
        }
        if name.hasSuffix("ys") {
            return name.substring(to: name.index(before: name.endIndex))
        }
        if name.hasSuffix("s") {
            return name.substring(to: name.index(before: name.endIndex))
        }

        // list of apophonic and irregular plurals

        return name
    }

    func camelCased() -> String {
        if isEmpty { return "" }

        var characterSet = CharacterSet.alphanumerics
        characterSet.formUnion(CharacterSet(charactersIn: "[]_"))
        let invalidCharacterSet = characterSet.inverted

        var camelCased = self
        while true {
            guard let range = camelCased.rangeOfCharacter(from: invalidCharacterSet) else {
                break
            }

            camelCased.replaceSubrange(range, with: "_")
        }

        while camelCased.contains("_") {
            let range = camelCased.range(of: "_")!
            let underlineRange = (range.lowerBound ..< range.upperBound)

            let endOfNextRange = underlineRange.upperBound == camelCased.endIndex ? camelCased.endIndex : camelCased.index(after: underlineRange.upperBound)
            let nextRange = (underlineRange.upperBound ..< endOfNextRange)
            let replacementRange = (underlineRange.lowerBound ..< nextRange.upperBound).clamped(to: (underlineRange.lowerBound ..< camelCased.endIndex))
            let initial = camelCased.substring(with: nextRange)
            camelCased.replaceSubrange(replacementRange, with: initial.uppercased())
        }
        
        return camelCased
    }
}
