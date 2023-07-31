import Foundation

internal extension String {
    func generatedClassName() -> String {
        if isEmpty { return "" }

        var generatedClassName = camelCased().depluralize()
        let replacementRange = (generatedClassName.startIndex ..< generatedClassName.index(after: generatedClassName.startIndex))
        let initial = generatedClassName[replacementRange]
        generatedClassName.replaceSubrange(replacementRange, with: initial.uppercased())
        return generatedClassName
    }

    func depluralize() -> String {
        if isEmpty { return "" }

        let name = self
        if name.hasSuffix("uies") {
			return name[..<name.index(name.endIndex, offsetBy: -4)].appending("y")
        }
        if name.hasSuffix("ices") {
            if [ "matrices" ].contains(name) {
                return "matrix"
            }

			return name[..<name.index(name.endIndex, offsetBy: -4)].appending("ex")
        }
        if name.hasSuffix("eaux") || name.hasSuffix("eaus") {
			return String(name[..<name.endIndex])
        }
        if name.hasSuffix("ves") {
			return name[..<name.index(name.endIndex, offsetBy: -3)].appending("f")
        }
        if name.hasSuffix("ata") {
            return name[..<name.index(name.endIndex, offsetBy: -3)].appending("ma")
        }
        if name.hasSuffix("mas") {
            return String(name[..<name.index(before: name.endIndex)])
        }
        if name.hasSuffix("ies") {
            if [ "series", "species" ].contains(name) {
                return name
            }

            return name[..<name.index(name.endIndex, offsetBy: -3)].appending("y")
        }
        if name.hasSuffix("ses") {
            return name[..<name.index(name.endIndex, offsetBy: -3)].appending("is")
        }
        if name.hasSuffix("es") {
            if name == "houses" {
                return "house"
            }

            return String(name[..<name.endIndex])
        }
        if name.hasSuffix("ae") {
            return String(name[..<name.endIndex])
        }
        if name.hasSuffix("um") {
            return name[..<name.endIndex].appending("a")
        }
        if name.hasSuffix("us") {
            if [ "status" ].contains(name) {
                return name
            }

            if [ "corpus" ].contains(name) {
                return name[..<name.index(before: name.endIndex)].appending("ora")
            }

            if [ "genus" ].contains(name) {
                return name[..<name.index(before: name.endIndex)].appending("era")
            }

            return name[..<name.index(before: name.endIndex)].appending("i")
        }
        if name.hasSuffix("en") {
            return String(name[..<name.endIndex])
        }
        if name.hasSuffix("fs") {
            return String(name[..<name.endIndex])
        }
        if name.hasSuffix("ys") {
            return String(name[..<name.endIndex])
        }
        if name.hasSuffix("s") {
            return String(name[..<name.endIndex])
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
            let initial = camelCased[nextRange]
            camelCased.replaceSubrange(replacementRange, with: initial.uppercased())
        }

        return camelCased.isEmpty ? "/* \(self) */ invalidKey" : camelCased
    }

	func linesPrefixedWithTab() -> String {
		var lines = [String]()
		(self as NSString).enumerateLines { (line, _) in
			lines.append("\t" + line)
		}
		return lines.joined(separator: "\n")
	}

}
