import Foundation

public struct Struct: CustomStringConvertible {
    var name: String
    let properties: Set<Property>

    public var description: String {
        let typeName = name.generatedClassName()
        var d = ""
        properties.forEach {
            if !$0.dateFormat.isEmpty {
                d += "\nprivate let \(typeName)DateFormatter\(abs($0.dateFormat.hashValue)): DateFormatter = {"
                d += "\n\tvar dateFormatter = DateFormatter()"
                d += "\n\tdateFormatter.dateFormat = \"\($0.dateFormat)\""
                d += "\n\treturn dateFormatter"
                d += "\n}()\n\n"
            }
        }

        d += "public struct \(typeName) {"
        if !properties.isEmpty {
            d += "\(propertyDeclarationCode)\n"
            d += "\n\(initCode)\n"
            d += "}\n"
            d += "\nextension \(typeName): Equatable {\n \(equatableCode) \n}\n"
            d += "\nextension \(typeName): Hashable {\n \(hashableCode) \n}"
        }
        return d
    }

    private var propertyDeclarationCode: String {
        let separator = "\n\tlet "
        let sorted = properties.sorted(by: { x, y in return x.name < y.name })
        return separator + sorted.map({
            let l = "\($0.name.camelCased()): \($0.type.generatedClassName())"
            if $0.isOptional { return "\(l)?" }
            return l
        }).joined(separator: separator)
    }

    private var initCode: String {
        var i = "\tinit(_ dictionary: [String: Any]) {"
        i += initInitializationCode
        i += "\n\t}"
        return i
    }

    private var initInitializationCode: String {
        let sorted = properties.sorted(by: { x, y in return x.name < y.name })
        let lets: [String] = sorted.map {
            if $0.isArray {
                if $0.internetPrimitive {
                    let a = $0.isOptional ? "as?" : "as!"
                    return "self.\($0.name.camelCased()) = dictionary[\"\($0.name)\"] \(a) \($0.type)"
                }

                if $0.isOptional {
                    var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? [[String: Any]] {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.name.camelCased()).flatMap { return \($0.name.generatedClassName())($0) }"
                    letString += "\n\t\t} else {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = nil"
                    letString += "\n\t\t}"
                    return letString
                }

                var letString = "\n\t\tlet \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as! [[String: Any]]"
                letString += "\n\t\tself.\($0.name.camelCased()) = \($0.name.camelCased()).flatMap { return \($0.name.generatedClassName())($0) }"
                return letString
            } else if !$0.internetPrimitive {
                if $0.isOptional {
                    var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? [String: Any] {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.type)(\($0.name.camelCased()))"
                    letString += "\n\t\t} else {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = nil"
                    letString += "\n\t\t}"
                    return letString
                }

                return "self.\($0.name.camelCased()) = \($0.type)(dictionary[\"\($0.name)\"] as! [String: Any])"
            } else if $0.isURL {
                if $0.isOptional {
                    return "self.\($0.name.camelCased()) = URL(string: (dictionary[\"\($0.name)\"] as? String))"
                }
                return "self.\($0.name.camelCased()) = URL(string: (dictionary[\"\($0.name)\"] as! String))!"
            } else if !$0.dateFormat.isEmpty {
                if $0.isOptional {
                    return "self.\($0.name.camelCased()) = \(name.generatedClassName())DateFormatter\(abs($0.dateFormat.hashValue)).date(from: (dictionary[\"\($0.name)\"] as? String))"
                }
                return "self.\($0.name.camelCased()) = \(name.generatedClassName())DateFormatter\(abs($0.dateFormat.hashValue)).date(from: (dictionary[\"\($0.name)\"] as! String))!"
            } else {
                let a = $0.isOptional ? "as?" : "as!"
                return "self.\($0.name.camelCased()) = dictionary[\"\($0.name)\"] \(a) \($0.type)"
            }
        }

        var combined = lets.map({ return $0 }).joined(separator: "\n\t\t")
        if !combined.hasPrefix("\n\t\t") {
            combined = "\n\t\t\(combined)"
        }

        return combined
    }

    private var equatableCode: String {
        var equation = "\tpublic static func ==(x: \(name.generatedClassName()), y: \(name.generatedClassName())) -> Bool {\n\t\treturn "
        let sorted = properties.sorted(by: { x, y in return x.name < y.name })
        let equations: [String] = sorted.map {
            if $0.isArray {
                if $0.isOptional {
                    var arrayEquation = "(x.\($0.name.camelCased())?.count ?? 0) == (y.\($0.name.camelCased())?.count ?? 0) && "
                    arrayEquation += "\n\t\t\t\t(0 ..< (x.\($0.name.camelCased())?.count ?? 0)).reduce(false, { $0 || x.\($0.name.camelCased())?[$1] == y.\($0.name.camelCased())?[$1] })"
                    return arrayEquation
                }

                var arrayEquation = "x.\($0.name.camelCased()).count == y.\($0.name.camelCased()).count && "
                arrayEquation += "\n\t\t\t\t(0 ..< x.\($0.name.camelCased()).count).reduce(false, { $0 || x.\($0.name.camelCased())[$1] == y.\($0.name.camelCased())[$1] })"
                return arrayEquation
            }

            return "x.\($0.name.camelCased()) == y.\($0.name.camelCased())"
        }
        equation += equations.joined(separator: " && \n\t\t\t")
        equation += "\n\t}"
        return equation
    }

    private var hashableCode: String {
        var hashable = "\tpublic var hashValue: Int {\n\t\treturn "
        let sorted = properties.sorted(by: { x, y in return x.name < y.name })
        let hashables: [String] = sorted.map {
            if $0.isArray {
                if $0.isOptional {
                    return "(\($0.name.camelCased())?.reduce(0, { return 33 &* $0 ^ $1.hashValue }) ?? 0)"
                }

                return "\($0.name.camelCased()).reduce(0, { return 33 &* $0 ^ $1.hashValue })"
            }

            if $0.isOptional {
                return "(\($0.name.camelCased())?.hashValue ?? 0)"
            }

            return "\($0.name.camelCased()).hashValue"
        }
        hashable += hashables.joined(separator: " ^ \n\t\t\t")
        hashable += "\n\t}"
        return hashable
    }
}

public struct Property: Equatable, Hashable {
    let name: String
    let type: String
    let internetPrimitive: Bool
    let dateFormat: String
    let isArray: Bool
    let isURL: Bool
    let isOptional: Bool

    init(name: String, type: String, dateFormat: String = "", internetPrimitive: Bool = true, isArray: Bool = false, isURL: Bool = false, isOptional: Bool = false) {
        self.name = name
        self.type = type
        self.dateFormat = dateFormat
        self.internetPrimitive = internetPrimitive
        self.isArray = isArray
        self.isURL = isURL
        self.isOptional = isOptional
    }

    public static func ==(x: Property, y: Property) -> Bool {
        return x.name == y.name &&
            x.type == y.type &&
            x.dateFormat == y.dateFormat &&
            x.internetPrimitive == y.internetPrimitive &&
            x.isArray == y.isArray &&
            x.isURL == y.isURL &&
            x.isOptional == y.isOptional
    }

    public var hashValue: Int {
        return name.hashValue ^
            type.hashValue ^
            dateFormat.hashValue ^
            internetPrimitive.hashValue ^
            isArray.hashValue ^
            isURL.hashValue ^
            isOptional.hashValue
    }
}

private let dateFormatter: DateFormatter = {
    var f: DateFormatter = DateFormatter()
    f.dateFormat = "eee MMM dd HH:mm:ss Z yyyy"
    return f
}()

public enum JSON {
    init?(value: Any) {
        if let int = value as? Int {
            self = .int(int)
        } else if let bool = value as? Bool {
            self = .bool(bool)
        } else if let double = value as? Double {
            self = .double(double)
        } else if let string = value as? String {
            if let date = dateFormatter.date(from: string) {
                self = .date(date, dateFormatter.dateFormat)
            } else if let url = URL(string: string), !(url.scheme ?? "").isEmpty {
                self = .url(url)
            } else {
                self = .string(string)
            }
        } else if let array = value as? [Any] {
            self = .array(array)
        } else if let dictionary = value as? [String: Any] {
            self = .dictionary(dictionary)
        } else if value is NSNull {
            self = .null
        } else {
            return nil
        }
    }

    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case date(Date, String)
    case url(URL)
    case array([Any])
    case dictionary([String: Any])
    case null

    var type: String {
        switch self {
        case .bool(_): return "Bool"
        case .int(_): return "Int"
        case .double(_): return "Double"
        case .string(_): return "String"
        case .date(_, _): return "Date"
        case .url(_): return "URL"
        case .array(_): return "Array"
        case .dictionary(_): return "Dictionary"
        case .null: return "null"
        }
    }
}

extension JSON: Hashable, Equatable {
    public var hashValue: Int { return type.hashValue }

    // this is wrong in the general sene, but right for what we use this for during codegen
    public static func ==(x: JSON, y: JSON) -> Bool {
        return x.type == y.type
    }
}

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

        var camelCased = self

        while camelCased.contains("_") {
            let range = camelCased.range(of: "_")!
            let underlineRange = (range.lowerBound ..< range.upperBound)
            let nextRange = (underlineRange.upperBound ..< camelCased.index(after: underlineRange.upperBound))
            let replacementRange = (underlineRange.lowerBound ..< nextRange.upperBound).clamped(to: (underlineRange.lowerBound ..< camelCased.endIndex))
            let initial = camelCased.substring(with: nextRange)
            camelCased.replaceSubrange(replacementRange, with: initial.uppercased())
        }

        return camelCased
    }
}
