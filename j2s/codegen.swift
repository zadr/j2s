import Foundation

public struct Struct: CustomStringConvertible {
    var name: String
    let properties: Set<Property>

    public var description: String {
        let typeName = name.generatedClassName()
        var d = ""
        properties.flatMap { (json) -> String? in
            if case .date(_, let format) = json.underlying { return format }
            return nil
        } .forEach {
            d += "\nprivate let \(typeName)DateFormatter\(abs($0.hashValue)): DateFormatter = {"
            d += "\n\tvar dateFormatter = DateFormatter()"
            d += "\n\tdateFormatter.dateFormat = \"\($0)\""
            d += "\n\treturn dateFormatter"
            d += "\n}()\n\n"
        }

        d += "public struct \(typeName) {"
        if !properties.isEmpty {
            d += "\(propertyDeclarationCode)\n"
            d += "\n\(initCode)\n"
            d += "}\n"
            d += "\nextension \(typeName): Equatable {\n \(equatableCode) \n}\n"
            d += "\nextension \(typeName): Hashable {\n \(hashableCode) \n}\n"
        } else {
            d += "}\n"
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
        var i = "\tinit?(_ dictionary: [String: Any]) {"
        i += initInitializationCode
        i += "\n\t}"
        return i
    }

    private var initInitializationCode: String {
        let sorted = properties.sorted(by: { x, y in return x.name < y.name })
        let lets: [String] = sorted.map { (property) in
            if case .date(_, let format) = property.underlying {
                if property.underlying.isArray && property.isOptional {
                    var letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? [String] {"
                    letString += "\n\t\t\tself.\(property.name.camelCased()) = \(property.name.camelCased()).flatMap {"
                    letString += "\n\t\t\t\treturn \(name.generatedClassName())DateFormatter\(abs(format.hashValue)).date(from: $0)"
                    letString += "\n\t\t\t}"
                    letString += "\n\t\t} else {"
                    letString += "\n\t\t\tself.\(property.name.camelCased()) = nil"
                    letString += "\n\t\t\t}"
                    return letString
                } else if property.isOptional {
                    var letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? String {"
                    letString += "\n\t\t\tself.\(property.name.camelCased()) = \(name.generatedClassName())DateFormatter\(abs(format.hashValue)).date(from: \(property.name.camelCased()))"
                    letString += "\n\t\t} else {"
                    letString += "\n\t\t\tself.\(property.name.camelCased()) = nil"
                    letString += "\n\t\t}"
                    return letString
                } else {
                    var letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? String {"
                    letString += "\n\t\t\tself.\(property.name.camelCased()) = \(name.generatedClassName())DateFormatter\(abs(format.hashValue)).date(from: \(property.name.camelCased()))"
                    letString += "\n\t\t} else {"
                    letString += "\n\t\t\treturn nil"
                    letString += "\n\t\t}"
                    return letString
                }
            } else if property.underlying.isArray && property.isOptional && !property.underlying.isComplexType {
                var letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? \(property.type) {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = \(property.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = nil"
                letString += "\n\t\t}"
                return letString
            } else if property.underlying.isArray && property.isOptional {
                var letString = ""
                if property.underlying.isStringEnhancement {
                    letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? [String] {"
                } else {
                    letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? [[String: Any]] {"
                }
                let parameterString = property.underlying.initializerParameter.isEmpty ? "" : "\(property.underlying.initializerParameter): "
                letString += "\n\t\t\tself.\(property.name.camelCased()) = \(property.name.camelCased()).flatMap { return \(property.type.generatedClassName())(\(parameterString)$0) }"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = nil"
                letString += "\n\t\t}"
                return letString
            } else if property.underlying.isArray && !property.underlying.isComplexType {
                var letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? \(property.type) {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = \(property.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\treturn nil"
                letString += "\n\t\t}"
                return letString
            } else if property.isOptional && !property.underlying.isComplexType {
                var letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? \(property.type) {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = \(property.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = nil"
                letString += "\n\t\t}"
                return letString
            } else if !property.underlying.isComplexType {
                var letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? \(property.type) {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = \(property.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\treturn nil"
                letString += "\n\t\t}"
                return letString
            } else if property.isOptional {
                var letString = ""
                if property.underlying.isStringEnhancement {
                    letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? String, "
                } else {
                    letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? [String: Any], "
                }

                let parameterString = property.underlying.initializerParameter.isEmpty ? "" : "\(property.underlying.initializerParameter): "
                letString += "\n\t\t\tlet _\(property.name.camelCased()) = \(property.type.generatedClassName())(\(parameterString)\(property.name.camelCased())) {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = _\(property.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = nil"
                letString += "\n\t\t}"
                return letString
            } else { // single non-optional object
                var letString = ""
                if property.underlying.isStringEnhancement {
                    letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? String, "
                } else {
                    letString = "\n\t\tif let \(property.name.camelCased()) = dictionary[\"\(property.name)\"] as? [String: Any], "
                }
                let parameterString = property.underlying.initializerParameter.isEmpty ? "" : "\(property.underlying.initializerParameter): "
                letString += "\n\t\t\tlet _\(property.name.camelCased()) = \(property.type.generatedClassName())(\(parameterString)\(property.name.camelCased())) {"
                letString += "\n\t\t\tself.\(property.name.camelCased()) = _\(property.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\treturn nil"
                letString += "\n\t\t}"
                return letString
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
            if $0.underlying.isArray && $0.isOptional {
                var arrayEquation = "(x.\($0.name.camelCased())?.count ?? 0) == (y.\($0.name.camelCased())?.count ?? 0) && "
                arrayEquation += "\n\t\t\t\t(0 ..< (x.\($0.name.camelCased())?.count ?? 0)).reduce(true, { $0 && x.\($0.name.camelCased())?[$1] == y.\($0.name.camelCased())?[$1] })"
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
            if $0.underlying.isArray {
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

    let underlying: JSON
    let isOptional: Bool

    init(name: String, type: String, isOptional: Bool = false, underlying: JSON) {
        self.name = name
        self.type = type
        self.underlying = underlying
        self.isOptional = isOptional
    }

    public static func ==(x: Property, y: Property) -> Bool {
        return x.name == y.name &&
            x.type == y.type &&
            x.underlying == y.underlying &&
            x.isOptional == y.isOptional
    }

    public var hashValue: Int {
        return name.hashValue ^
            type.hashValue ^
            isOptional.hashValue ^
            underlying.hashValue
    }
}

private let dateFormatters: [DateFormatter] = [
    {
        var f: DateFormatter = DateFormatter()
        f.dateFormat = "eee MMM dd HH:mm:ss Z yyyy"
        return f
    }()
]

public enum JSON {
    init?(value: Any) {
        if let number = value as? NSNumber {
            switch CFNumberGetType(number) {
            case .charType: self = .bool(value as! Bool)

            case .shortType: fallthrough
            case .sInt8Type: fallthrough
            case .sInt16Type: fallthrough
            case .sInt32Type: fallthrough
            case .intType: fallthrough
            case .longType: fallthrough
            case .cfIndexType: fallthrough
            case .sInt64Type: fallthrough
            case .longLongType: fallthrough
            case .nsIntegerType: self = .int(value as! Int)

            case .floatType: fallthrough
            case .float32Type: fallthrough
            case .float64Type: fallthrough
            case .doubleType: fallthrough
            case .cgFloatType: self = .double(value as! Double)
            }
        } else if let string = value as? String {
            for dateFormatter in dateFormatters {
                if let date = dateFormatter.date(from: string) {
                    self = .date(date, dateFormatter.dateFormat)
                    return
                }
            }

            if let url = URL(string: string), !(url.scheme ?? "").isEmpty {
                self = .url(url)
            } else if string.isBCP47Identifier  {
                self = .locale(Locale(identifier: string))
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
    case locale(Locale)
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
        case .locale(_): return "Locale"
        case .array(_): return "Array"
        case .dictionary(_): return "Dictionary"
        case .null: return "null"
        }
    }

    var isArray: Bool {
        switch self {
        case .array(_): return true
        default: return false
        }
    }

    var isStringEnhancement: Bool {
        switch self {
        case .url(_): return true
        case .locale(_): return true
        default: return false
        }
    }

    var isComplexType: Bool {
        switch self {
        case .dictionary(_): return true
        default: return false
        }
    }

    var initializerParameter: String {
        switch self {
        case .url(_): return "string"
        case .locale(_): return "localeIdentifier"
        default: return ""
        }
    }
}

extension JSON: Hashable, Equatable {
    public var hashValue: Int {
        switch self {
        case .bool(let x): return x.hashValue
        case .int(let x): return x.hashValue
        case .string(let x): return x.hashValue
        case .date(let x1, let x2): return x1.hashValue ^ x2.hashValue
        case .url(let x): return x.hashValue
        case .locale(let x): return x.hashValue
        case .array(_): return type.hashValue
        case .dictionary(_): return type.hashValue
        case .null: return type.hashValue
        default: return 0
        }
    }

    // this isn't always right in the general sene, but it's usually right enough for what we use it for during codegen
    public static func ==(x: JSON, y: JSON) -> Bool {
        switch (x, y) {
        case (.bool(let x), .bool(let y)): return x == y
        case (.int(let x), .int(let y)): return x == y
        case (.string(let x), .string(let y)): return x == y
        case (.date(let x1, let x2), .date(let y1, let y2)): return x1 == y1 && x2 == y2
        case (.url(let x), .url(let y)): return x == y
        case (.locale(let x), .locale(let y)): return x == y
        case (.array(_), .array(_)): return true
        case (.dictionary(_), .dictionary(_)): return true
        case (.null, .null): return x == y
        default: return false
        }
    }
}
