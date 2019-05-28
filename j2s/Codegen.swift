import Foundation

public class Struct {
    var name: String
    let properties: Set<Property>

	var parent: Struct? = nil
	var children = [Struct]()

	var recursiveTypeName: String {
		var typeName = name.generatedClassName()
		var p: Struct? = parent

		while p != nil {
			typeName = "\(p!.name.generatedClassName()).\(typeName)"
			p = p?.parent
		}

		return typeName
	}

	init(name: String, properties: Set<Property>) {
		self.name = name
		self.properties = properties
	}

    public var structDeclaration: String {
        let typeName = name.generatedClassName()
		var code = """
		public struct \(typeName): Codable {
			\(propertyDeclarationCode)
		"""

		if !children.isEmpty {
			code += "\n\n"
			code += children.map({
				return $0.structDeclaration.linesPrefixedWithTab()
			}).joined(separator: "\n\t")
		}

		let codingKeys = codingKeysCode
		if !codingKeys.isEmpty {
			code += "\n\n"
			code += """
				\(codingKeys)
			"""
		}

		code += "\n}"

		return code
	}

	public var extensionDeclaration: String {
		return """
		extension \(recursiveTypeName) {
		\(singleInitCode)

		\(multipleInitCode)
		}
		"""
    }

    private var propertyDeclarationCode: String {
        if properties.isEmpty { return "" }

		let sorted = properties.sorted(by: { x, y in return x.name < y.name })
        return "public let " + sorted.map({
            let l = "\($0.name.camelCased()): \($0.type.generatedClassName())"
            if $0.isOptional { return "\(l)?" }
            return l
        }).joined(separator: "\n\tlet ")
    }

	private var singleInitCode: String {
		var strategies = Set<JSONDecoder.DateDecodingStrategy>()
		for property in properties {
			if case .date(_, let strategy) = property.underlying {
				strategies.insert(strategy)
			}
		}

		if strategies.isEmpty {
			return """
			\tpublic static func create(with data: Data) throws -> \(recursiveTypeName)  {
				\treturn try JSONDecoder().decode(\(recursiveTypeName).self, from: data)
			\t}
			"""
		} else if strategies.contains(.iso8601) {
			return """
			\tpublic static func create(with data: Data) throws -> \(recursiveTypeName)  {
				\tlet decoder = JSONDecoder()
				\tdecoder.dateDecodingStrategy = .iso8601
				\treturn try decoder.decode(\(recursiveTypeName).self, from: data)
			\t}
			"""
		} else {
			assert(strategies.isEmpty || strategies.count == 1)
			fatalError()
		}
	}

	private var multipleInitCode: String {
		var strategies = Set<JSONDecoder.DateDecodingStrategy>()
		for property in properties {
			if case .date(_, let strategy) = property.underlying {
				strategies.insert(strategy)
			}
		}

		if strategies.isEmpty {
			return """
			\tpublic static func create(with data: Data) throws -> [\(recursiveTypeName)]  {
				\treturn try JSONDecoder().decode([\(recursiveTypeName)].self, from: data)
			\t}
			"""
		} else if strategies.contains(.iso8601) {
			return """
			\tpublic static func create(with data: Data) throws -> [\(recursiveTypeName)]  {
				\tlet decoder = JSONDecoder()
				\tdecoder.dateDecodingStrategy = .iso8601
				\treturn try decoder.decode([\(recursiveTypeName)].self, from: data)
			\t}
			"""
		} else {
			assert(strategies.isEmpty || strategies.count == 1)
			fatalError()
		}
	}

	private var codingKeysCode: String {
		let sorted = properties.sorted(by: { x, y in return x.name < y.name })
		var modified = false // map having side effects is :/
		let codingKeys = sorted.map({ (p: Property) -> String in
			let camelCased = p.name.camelCased()
			if camelCased == p.name {
				return "\tcase \(p.name)"
			}

			modified = true
			return "\tcase \(camelCased) = \"\(p.name)\""
		}).joined(separator: "\n\t")

		if modified {
			return "private enum CodingKeys: String, CodingKey {\n\t" + codingKeys + "\n\t}"
		}

		return ""
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
			if let date = ISO8601DateFormatter().date(from: string) {
				self = .date(date, .iso8601)
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
    case date(Date, JSONDecoder.DateDecodingStrategy)
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

extension JSONDecoder.DateDecodingStrategy: Equatable {
	public static func ==(x: JSONDecoder.DateDecodingStrategy, y: JSONDecoder.DateDecodingStrategy) -> Bool {
		switch (x, y) {
		case (.custom(_), .custom(_)): return false
		case (.formatted(let fx), .formatted(let fy)): return fx == fy
		case (.deferredToDate, .deferredToDate): return true
		case (.iso8601, .iso8601): return true
		case (.millisecondsSince1970, .millisecondsSince1970): return true
		case (.secondsSince1970, .secondsSince1970): return true
		default: return false
		}
	}
}

extension JSONDecoder.DateDecodingStrategy: Hashable {
	public var hashValue: Int {
		switch self {
		case .custom(_): fatalError() // unused
		case .formatted(let f): return f.hashValue
		case .deferredToDate: return 1
		case .iso8601: return 8601
		case .millisecondsSince1970: return 10
		case .secondsSince1970: return 100
		}
	}
}
