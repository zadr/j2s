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

		d += "public struct \(typeName): Codable {"
        d += "\(propertyDeclarationCode)\n"
        d += "}\n"
        return d
    }

    private var propertyDeclarationCode: String {
        if properties.isEmpty { return "" }

        let separator = "\n\tlet "
        let sorted = properties.sorted(by: { x, y in return x.name < y.name })
        return separator + sorted.map({
            let l = "\($0.name.camelCased()): \($0.type.generatedClassName())"
            if $0.isOptional { return "\(l)?" }
            return l
        }).joined(separator: separator)
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
        return x.name == y.name && x.type == y.type && x.isOptional == y.isOptional
    }

    public var hashValue: Int {
        return name.hashValue ^ type.hashValue ^ isOptional.hashValue
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

            /* if let url = URL(string: string), !(url.scheme ?? "").isEmpty {
                self = .url(url)
            }  else { */
                self = .string(string)
//            }
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

    var isArray: Bool {
        switch self {
        case .array(_): return true
        default: return false
        }
    }

    var isStringEnhancement: Bool {
        switch self {
        case .url(_): return true
        default: return false
        }
    }

    var isComplexType: Bool {
        switch self {
        case .dictionary(_): return true
        case .url(_): return true
        default: return false
        }
    }

    var initializerParameter: String {
        switch self {
        case .url(_): return "string"
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
        case (.array(_), .array(_)): return true
        case (.dictionary(_), .dictionary(_)): return true
        case (.null, .null): return x == y
        default: return false
        }
    }
}
