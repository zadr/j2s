func structify(name: String = "root", json: [String: Any]) -> [Struct] {
    var structs = [Struct]()
    var properties = Set<Property>()

    json.forEach {
        var handleJSON: ((String, JSON) -> String?)? = nil
        handleJSON = { (name, json) in
            switch json {
            case .bool(_): properties.insert(Property(name: name, type: "Bool"))
            case .int(_): properties.insert(Property(name: name, type: "Int"))
            case .double(_): properties.insert(Property(name: name, type: "Double"))
            case .string(_): properties.insert(Property(name: name, type: "String"))
            case .null: properties.insert(Property(name: name, type: "NSNull"))
            case .date(_, let format): properties.insert(Property(name: name, type: "Date", dateFormat: format))
            case .url(_): properties.insert(Property(name: name, type: "URL", initializerParameter: "string", internetPrimitive: false))
            case .locale(_): properties.insert(Property(name: name, type: "Locale", initializerParameter: "identifier", internetPrimitive: false))
            case .dictionary(let d):
                properties.insert(Property(name: name, type: name.generatedClassName(), internetPrimitive: false))
                structs.append(contentsOf: structify(name: name, json: d))
            case .array(let a):
                var types = [String: Int]()
                var jsons = [JSON]()

                a.forEach {
                    let j = JSON(value: $0)!
                    jsons.append(j)

                    var value = types[j.type] ?? 0
                    value += 1
                    types[j.type] = value
                }

                if types.keys.count == 1 {
                    var returnValue = ""
                    for i in 0 ..< jsons.count {
                        let json = jsons[i]

                        switch json {
                        case .bool(_):
                            properties.insert(Property(name: name, type: "[Bool]", isArray: true))
                        case .int(_):
                            properties.insert(Property(name: name, type: "[Int]", isArray: true))
                        case .double(_): properties.insert(Property(name: name, type: "[Double]", isArray: true))
                        case .string(_): properties.insert(Property(name: name, type: "[String]", isArray: true))
                        case .date(_): properties.insert(Property(name: name, type: "[Date]", isArray: true))
                        case .url(_):  properties.insert(Property(name: name, type: "[URL]", initializerParameter: "string", internetPrimitive: false, isArray: true))
                        case .locale(_): properties.insert(Property(name: name, type: "[Locale]", initializerParameter: "identifier", internetPrimitive: false, isArray: true))
                        case .array(let a):
                            let subjson = JSON(value: a)!
                            let type = handleJSON!(name, subjson)
                            let internetPrimitive = subjson.type.lowercased() != "array" && subjson.type.lowercased() != "dictionary"
                            let property = Property(name: name, type: "[\(type!.generatedClassName())]", internetPrimitive: internetPrimitive, isArray: true)
                            properties.insert(property)
                            returnValue = "[\(type!.generatedClassName())]"
                        case .dictionary(let d):
                            structs.append(contentsOf: structify(name: name, json: d))
                            properties.insert(Property(name: name, type: "[\(name.generatedClassName())]", internetPrimitive: false, isArray: true))
                            returnValue = name.generatedClassName()
                        case .null: properties.insert(Property(name: name, type: "[NSNull]", isArray: true))
                        }
                    }

                    if !returnValue.isEmpty { return returnValue }
                } else {
                    if types.keys.count == 2 {
                        let hasInt = types.keys.reduce(false) { return $0 || $1.lowercased() == "int" }
                        let hasBool = types.keys.reduce(false) { return $0 || $1.lowercased() == "bool" }

                        if hasInt && hasBool {
                            properties.insert(Property(name: name, type: "[Int]", isArray: true))
                        } else {
                            properties.insert(Property(name: name, type: "[Any]", isArray: true))
                        }
                    } else {
                        properties.insert(Property(name: name, type: "[Any]", isArray: true))
                    }
                }
            }

            return json.type
        }

        if let json = JSON(value: $0.1) {
            _ = handleJSON!($0.0, json)
        }
    }

    structs.append(Struct(name: name, properties: properties))

    return structs.merge()
}

extension Sequence where Iterator.Element == Struct {
    func merge() -> [Struct] {
        return reduce([String: Struct](), {
            var structs = $0
            if let existing = $0[$1.name.generatedClassName()] {
                let existsInBoth = $1.properties.intersection(existing.properties)
                let allProperties = $1.properties.union(existing.properties)
                let optionalProperties = allProperties.subtracting(existsInBoth).map {
                    return Property(name: $0.name, type: $0.type, internetPrimitive: $0.internetPrimitive, isArray: $0.isArray, isOptional: true)
                }

                let uniqueProperties = existsInBoth.union(optionalProperties).reduce([String: Property]()) {
                    var properties = $0
                    if let existing = $0[$1.name] {

                        if existing.type == "NSNull" && $1.type != "NSNull" {
                            properties[$1.name] = Property(name: $1.name, type: $1.type, initializerParameter: $1.initializerParameter, internetPrimitive: $1.internetPrimitive, isArray: $1.isArray, isOptional: true)
                        } else if existing.type != "NSNull" && $1.type == "NSNull" {
                            properties[$1.name] = Property(name: $1.name, type: existing.type, initializerParameter: $1.initializerParameter, internetPrimitive: $1.internetPrimitive, isArray: $1.isArray, isOptional: true)
                        } else {
                            properties[$1.name] = Property(name: $1.name, type: "Any", initializerParameter: $1.initializerParameter, internetPrimitive: $1.internetPrimitive, isArray: $1.isArray, isOptional: true)
                        }
                    } else {
                        properties[$1.name] = $1
                    }

                    return properties
                }

                structs[$1.name.generatedClassName()] = Struct(name: $1.name, properties: Set(uniqueProperties.values))
            } else {
                structs[$1.name.generatedClassName()] = $1
            }
            
            return structs
        }).values.sorted(by: { (x, y) -> Bool in
            return x.name < y.name
        })
    }
}
