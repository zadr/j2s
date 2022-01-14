func structify(name: String = "root", json: [String: Any]) -> [Struct] {
  var structs = [Struct]()
  var properties = Set<Property>()

  json.forEach {
    var handleJSON: ((String, JSON) -> String?)? = nil
    handleJSON = { (name, json) in
      switch json {
      case .bool(_): properties.insert(Property(name: name, type: "Bool", underlying: json))
      case .int(_): properties.insert(Property(name: name, type: "Int", underlying: json))
      case .double(_): properties.insert(Property(name: name, type: "Double", underlying: json))
      case .string(_): properties.insert(Property(name: name, type: "String", underlying: json))
      case .uuid(_): properties.insert(Property(name: name, type: "UUID", underlying: json))
      case .null: properties.insert(Property(name: name, type: "Any?", underlying: json))
      case .date(_, _): properties.insert(Property(name: name, type: "Date", underlying: json))
      case .url(_): properties.insert(Property(name: name, type: "URL", underlying: json))
      case .dictionary(let d):
        properties.insert(Property(name: name, type: name.generatedClassName(), underlying: json))
        let s = structify(name: name, json: d)
        structs.append(contentsOf: s)
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
              properties.insert(Property(name: name, type: "[Bool]", underlying: json))
            case .int(_):
              properties.insert(Property(name: name, type: "[Int]", underlying: json))
            case .double(_): properties.insert(Property(name: name, type: "[Double]", underlying: json))
            case .string(_): properties.insert(Property(name: name, type: "[String]", underlying: json))
            case .uuid(_): properties.insert(Property(name: name, type: "[UUID]", underlying: json))
            case .date(_, _): properties.insert(Property(name: name, type: "[Date]", underlying: json))
            case .url(_):  properties.insert(Property(name: name, type: "[URL]", underlying: json))
            case .array(let a):
              let subjson = JSON(value: a)!
              let type = handleJSON!(name, subjson)
              let property = Property(name: name, type: "[\(type!.generatedClassName())]", underlying: json)
              properties.insert(property)
              returnValue = "[\(type!.generatedClassName())]"
            case .dictionary(let d):
              structs.append(contentsOf: structify(name: name, json: d))
              properties.insert(Property(name: name, type: "[\(name.generatedClassName())]", underlying: json))
              returnValue = name.generatedClassName()
            case .null: properties.insert(Property(name: name, type: "[Any?]", underlying: json))
            }
          }

          if !returnValue.isEmpty { return returnValue }
        } else {
          if types.keys.isEmpty {
            properties.insert(Property(name: name, type: name.generatedClassName(), underlying: json))
          } else if types.keys.count == 2 {
            let hasInt = types.keys.reduce(false) { return $0 || $1.lowercased() == "int" }
            let hasBool = types.keys.reduce(false) { return $0 || $1.lowercased() == "bool" }

            if hasInt && hasBool {
              properties.insert(Property(name: name, type: "[Int]", underlying: json))
            } else {
              properties.insert(Property(name: name, type: "[Any]", underlying: json))
            }
          } else {
            properties.insert(Property(name: name, type: "[Any]", underlying: json))
          }
        }
      }

      return json.type
    }

    if let json = JSON(value: $0.1) {
      _ = handleJSON!($0.0, json)
    }
  }

  let s = Struct(name: name, properties: properties)
  let children = structs.merge()
  children.forEach { $0.parent = s }
  s.children = children
  structs = [ s ]

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
          return Property(name: $0.name, type: $0.type, isOptional: true, underlying: $0.underlying)
        }

        let uniqueProperties = existsInBoth.union(optionalProperties).reduce([String: Property]()) {
          var properties = $0
          if let existing = $0[$1.name] {
            if (existing.type == "Any?" || existing.type == "Any") && ($1.type != "Any?" && $1.type != "Any") {
              properties[$1.name] = Property(name: $1.name, type: $1.type, isOptional: true, underlying: $1.underlying)
            } else if (existing.type != "Any?" || existing.type != "Any") && ($1.type == "Any?" || $1.type == "Any" ) {
              properties[$1.name] = Property(name: $1.name, type: existing.type, isOptional: true, underlying: $1.underlying)
            } else {
              switch (existing.underlying, $1.underlying) {
              case (.string(_), .url(_)): properties[$1.name] = Property(name: $1.name, type: existing.type, isOptional: existing.isOptional || existing.isOptional, underlying: existing.underlying)
              default: properties[$1.name] = Property(name: $1.name, type: "Any", isOptional: true, underlying: $1.underlying)
              }
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
