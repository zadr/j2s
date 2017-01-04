## What's this?
j2s is a macOS app that converts [JSON](https://en.wikipedia.org/wiki/JSON) dictionaries into [Swift](https://swift.org) `struct`s. It also outputs implementations of [Equatable](https://developer.apple.com/reference/swift/equatable) and [Hashable](https://developer.apple.com/reference/swift/hashable) for every `struct` it generates.

![Screenshot](Screenshot.png?raw=true)

## That's it? Can I make it do anything else?
No, yeah, that's it. You give j2s json and it gives you Swift structs. You can pick if it outputs to one file or a _n_ files for _n_ structs.

If you want to make it do anything else, you'll have to write some more code. I'll probably accept pull requests, but, you should probably look into other tools like [Sourcery](https://github.com/krzysztofzablocki/Sourcery) instead.

## Okay
Oh. j2s will convert snake_case_key_names into camelCasePropertyNames, and if you have a key where the value is an array of of dictionaries, the key name will be — naively — [depluralized](https://github.com/zadr/j2s/blob/main/j2s/StringTransformations.swift#L14) (exact line of code may change, but look around there for the algorithm).

And, if your json value is a string that's secretly a `URL` (like `https://github.com/zadr/j2s`), a `Date` in a format that j2s understands (like `Sat Dec 31 04:27:14 +0000 2016`), or a `Locale` (in [BCP47](https://tools.ietf.org/html/bcp47) format, ex: `en-US` or `es_ES`), the generated code will use the correct (`URL`, `Date` or `Locale`) type.

Also, an `Int` like `5` is an `Int` and a floating point number like `5.0` is a `Double`. Because, you know, thats how these things should work.

## What version of Swift does this target?
j2s.xcodeproj requires Swift 3 (Xcode 8 or greater) to build. The code it outputs also requires Swift 3.

## What's the generated code look like?

j2s can take in the following JSON:

```json
{
  "what_if_i_want_to" : [
    "type? sure, but uncheck the \"Pretty-Print JSON\" box down there --v",
    "boogie? wouldn't dream of stopping you"
  ],
  "why" : "to see swift structs over there -->",
  "what" : "paste json here"
}
```

and turn it into Swift code that looks like this:

```swift
public struct Demo {
	let what: String
	let whatIfIWantTo: [String]
	let why: String

	init?(_ dictionary: [String: Any]) {
		if let what = dictionary["what"] as? String {
			self.what = what
		} else {
			return nil
		}
		
		if let whatIfIWantTo = dictionary["what_if_i_want_to"] as? [String] {
			self.whatIfIWantTo = whatIfIWantTo
		} else {
			return nil
		}
		
		if let why = dictionary["why"] as? String {
			self.why = why
		} else {
			return nil
		}
	}
}

extension Demo: Equatable {
 	public static func ==(x: Demo, y: Demo) -> Bool {
		return x.what == y.what && 
			x.whatIfIWantTo.count == y.whatIfIWantTo.count && 
				(0 ..< x.whatIfIWantTo.count).reduce(true, { $0 && x.whatIfIWantTo[$1] == y.whatIfIWantTo[$1] }) && 
			x.why == y.why
	} 
}

extension Demo: Hashable {
 	public var hashValue: Int {
		return what.hashValue ^ 
			whatIfIWantTo.reduce(0, { return 33 &* $0 ^ $1.hashValue }) ^ 
			why.hashValue
	} 
}
```

## What about Optionals? I don't see any Optionals.
Optionals are sort of handled by j2s. JSON doesn't have Optionals, so it's hard to map them over automatically.

While parsing, if j2s is told to create the same `struct` multiple times, it considers any properties that don't exist in both models to be [Optional](http://swiftdoc.org/v3.0/type/Optional/). 

The same is also true for properties that show up as `null` and as a `Type`.

`null`s are turned into `NSNull`.

## Oh.
Yeah. Usually happens in the case of an array of dictionaries. This json:

```json
{
  "foo" : [
    {
      "bar" : 42,
      "baz" : true,
      "color" : null
    },
    {
      "bar" : 42,
      "gizmo" : "raygun",
      "color" : "purple"
    }
  ]
}
```

will generate this Swift code:

```swift
public struct Demo {
	let foo: [Foo]

	init?(_ dictionary: [String: Any]) {
		if let foo = dictionary["foo"] as? [String: Any] {
			self.foo = Foo(foo)
		} else {
			return nil
		}
	}
}

extension Demo: Equatable {
 	public static func ==(x: Demo, y: Demo) -> Bool {
		return x.foo.count == y.foo.count && 
				(0 ..< x.foo.count).reduce(true, { $0 && x.foo[$1] == y.foo[$1] })
	} 
}

extension Demo: Hashable {
 	public var hashValue: Int {
		return foo.reduce(0, { return 33 &* $0 ^ $1.hashValue })
	} 
}

// MARK: -

public struct Foo {
	let bar: Int
	let baz: Bool?
	let color: String?
	let gizmo: String?

	init?(_ dictionary: [String: Any]) {
		if let bar = dictionary["bar"] as? Int {
			self.bar = bar
		} else {
			return nil
		}
		
		if let baz = dictionary["baz"] as? Bool {
			self.baz = baz
		} else {
			self.baz = nil
		}
		
		if let color = dictionary["color"] as? String {
			self.color = color
		} else {
			self.color = nil
		}
		
		if let gizmo = dictionary["gizmo"] as? String {
			self.gizmo = gizmo
		} else {
			self.gizmo = nil
		}
	}
}

extension Foo: Equatable {
 	public static func ==(x: Foo, y: Foo) -> Bool {
		return x.bar == y.bar && 
			x.baz == y.baz && 
			x.color == y.color && 
			x.gizmo == y.gizmo
	} 
}

extension Foo: Hashable {
 	public var hashValue: Int {
		return bar.hashValue ^ 
			(baz?.hashValue ?? 0) ^ 
			(color?.hashValue ?? 0) ^ 
			(gizmo?.hashValue ?? 0)
	} 
}
```

## Why build this and not use some other tool?
There are other awesome codegen tools out there, but, couldn't find anything that:

1. Accepted json, and then…
2. …Output Swift `struct`s…
3. …Along with implementations of `Equatable` and `Hashable`…
4. …Without having to go through an intermediary codegen format.

## Still hung up on depluralization? (Singularity?)
A json dictionary with a key named `potatoes`, where the value is a list of dictionaries will be given the Swift type `[Potato]`. Similarly, `soliloquies` becomes `[Soliloquy]`, `dwarves` and `[Dwarf]`, and so on. Depluralization is a giant `if` statement though, so while `indices` becomes `[Index]`, `matrices` incorrectly becomes `matrex`.

## Okay then
Before you go, remember that j2s code is released under a [2-Clause BSD License](LICENSE.md) and all contributions and project activity should be in line with our [Code of Conduct](CODE_OF_CONDUCT.md).
