import Foundation

public struct Struct: CustomStringConvertible {
    var name: String
    let properties: Set<Property>

    public var description: String {
        let typeName = name.generatedClassName()
        var d = ""
        properties.filter {
            return !$0.dateFormat.isEmpty
        } .forEach {
            d += "\nprivate let \(typeName)DateFormatter\(abs($0.dateFormat.hashValue)): DateFormatter = {"
            d += "\n\tvar dateFormatter = DateFormatter()"
            d += "\n\tdateFormatter.dateFormat = \"\($0.dateFormat)\""
            d += "\n\treturn dateFormatter"
            d += "\n}()\n\n"
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
        var i = "\tinit?(_ dictionary: [String: Any]) {"
        i += initInitializationCode
        i += "\n\t}"
        return i
    }

    private var initInitializationCode: String {
        let sorted = properties.sorted(by: { x, y in return x.name < y.name })
        let lets: [String] = sorted.map {
            if !$0.dateFormat.isEmpty {
                if $0.isArray && $0.isOptional {
                    var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? [String] {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.name.camelCased()).flatMap {"
                    letString += "\n\t\t\t\treturn \(name.generatedClassName())DateFormatter\(abs($0.dateFormat.hashValue)).date(from: $0)"
                    letString += "\n\t\t\t}"
                    letString += "\n\t\t} else {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = nil"
                    letString += "\n\t\t\t}"
                    return letString
                } else if $0.isOptional {
                    var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? String {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = \(name.generatedClassName())DateFormatter\(abs($0.dateFormat.hashValue)).date(from: \($0.name.camelCased()))"
                    letString += "\n\t\t} else {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = nil"
                    letString += "\n\t\t}"
                    return letString
                } else {
                    var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? String {"
                    letString += "\n\t\t\tself.\($0.name.camelCased()) = \(name.generatedClassName())DateFormatter\(abs($0.dateFormat.hashValue)).date(from: \($0.name.camelCased()))"
                    letString += "\n\t\t} else {"
                    letString += "\n\t\t\treturn nil"
                    letString += "\n\t\t}"
                    return letString
                }
            } else if $0.isArray && $0.isOptional && $0.internetPrimitive {
                var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? \($0.type) {"
                letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\tself.\($0.name.camelCased()) = nil"
                letString += "\n\t\t}"
                return letString
            } else if $0.isArray && $0.isOptional {
                var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? [[String: Any]] {"
                let parameterString = $0.initializerParameter.isEmpty ? "" : "\($0.initializerParameter): "
                letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.name.camelCased()).flatMap { return \($0.type.generatedClassName())(\(parameterString)$0) }"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\tself.\($0.name.camelCased()) = nil"
                letString += "\n\t\t}"
                return letString
            } else if $0.isArray && $0.internetPrimitive {
                var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? \($0.type) {"
                letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\treturn nil"
                letString += "\n\t\t}"
                return letString
            } else if $0.isOptional && $0.internetPrimitive {
                var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? \($0.type) {"
                letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\tself.\($0.name.camelCased()) = nil"
                letString += "\n\t\t}"
                return letString
            } else if $0.internetPrimitive {
                var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? \($0.type) {"
                letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.name.camelCased())"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\treturn nil"
                letString += "\n\t\t}"
                return letString
            } else if $0.isOptional {
                var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? [String: Any] {"
                let parameterString = $0.initializerParameter.isEmpty ? "" : "\($0.initializerParameter): "
                letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.type.generatedClassName())(\(parameterString)\($0.name.camelCased()))"
                letString += "\n\t\t} else {"
                letString += "\n\t\t\tself.\($0.name.camelCased()) = nil"
                letString += "\n\t\t}"
                return letString
            } else { // single non-optional object
                var letString = "\n\t\tif let \($0.name.camelCased()) = dictionary[\"\($0.name)\"] as? [String: Any] {"
                let parameterString = $0.initializerParameter.isEmpty ? "" : "\($0.initializerParameter): "
                letString += "\n\t\t\tself.\($0.name.camelCased()) = \($0.type.generatedClassName())(\(parameterString)\($0.name.camelCased()))"
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
            if $0.isArray {
                if $0.isOptional {
                    var arrayEquation = "(x.\($0.name.camelCased())?.count ?? 0) == (y.\($0.name.camelCased())?.count ?? 0) && "
                    arrayEquation += "\n\t\t\t\t(0 ..< (x.\($0.name.camelCased())?.count ?? 0)).reduce(true, { $0 && x.\($0.name.camelCased())?[$1] == y.\($0.name.camelCased())?[$1] })"
                    return arrayEquation
                }

                var arrayEquation = "x.\($0.name.camelCased()).count == y.\($0.name.camelCased()).count && "
                arrayEquation += "\n\t\t\t\t(0 ..< x.\($0.name.camelCased()).count).reduce(true, { $0 && x.\($0.name.camelCased())[$1] == y.\($0.name.camelCased())[$1] })"
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
    let isArray: Bool
    let isOptional: Bool

    let dateFormat: String
    let initializerParameter: String

    init(name: String, type: String, initializerParameter: String = "", dateFormat: String = "", internetPrimitive: Bool = true, isArray: Bool = false, isOptional: Bool = false) {
        self.name = name
        self.type = type
        self.dateFormat = dateFormat
        self.initializerParameter = initializerParameter
        self.internetPrimitive = internetPrimitive
        self.isArray = isArray
        self.isOptional = isOptional
    }

    public static func ==(x: Property, y: Property) -> Bool {
        return x.name == y.name &&
            x.type == y.type &&
            x.dateFormat == y.dateFormat &&
            x.initializerParameter == y.initializerParameter &&
            x.internetPrimitive == y.internetPrimitive &&
            x.isArray == y.isArray &&
            x.isOptional == y.isOptional
    }

    public var hashValue: Int {
        return name.hashValue ^
            type.hashValue ^
            dateFormat.hashValue ^
            initializerParameter.hashValue ^
            internetPrimitive.hashValue ^
            isArray.hashValue ^
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
