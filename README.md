## What's this?
j2s is a macOS app that converts [JSON](https://en.wikipedia.org/wiki/JSON) dictionaries into [Swift](https://swift.org) `struct`s. It also outputs implementations of [Equatable](https://developer.apple.com/reference/swift/equatable) and [Hashable](https://developer.apple.com/reference/swift/hashable) for every `struct` it generates.

![Screenshot](Screenshot.png?raw=true)

## That's it? Can I make it do anything else?
No, yeah, that's it. You give j2s json and it gives you Swift structs. You can pick if it outputs to one file or a _n_ files for _n_ structs.

If you want to make it do anything else, you'll have to write some more code. I'll probably accept pull requests, but, you should probably look into other tools like [Sourcery](https://github.com/krzysztofzablocki/Sourcery) instead.

## What version of Swift does this target?
j2s.xcodeproj requires Swift 3 (Xcode 8 or greater) to build. The code it outputs also requires Swift 3, but only because generated `Equatable` implementations are in an `extension`.

## What's the generated code look like?

j2s can take in the following JSON:

```json
{
  "what" : "paste json here",
  "why" : "to see swift structs over there -->",
  "what_if_i_want_to" : [
    "type? go for it, but uncheck the \"Pretty-Print JSON\" box down there first --v",
    "boogie? wouldn't dream of stopping you"
  ],
  "cool" : true
}
```

and turn it into Swift code that looks like this:

```swift
public struct Demo {
	let cool: Bool
	let what: String
	let whatIfIWantTo: [String]
	let why: String

	init(_ dictionary: [String: Any]) {
		self.cool = dictionary["cool"] as! Bool
		self.what = dictionary["what"] as! String
		self.whatIfIWantTo = dictionary["what_if_i_want_to"] as! [String]
		self.why = dictionary["why"] as! String
	}
}

extension Demo: Equatable {
 	static func ==(x: Demo, y: Demo) -> Bool {
		return x.cool == y.cool && 
			x.what == y.what && 
			x.whatIfIWantTo.count == y.whatIfIWantTo.count && 
				(0 ..< whatIfIWantTo.count).reduce(false, { $0 || x.whatIfIWantTo[$1] == y.whatIfIWantTo[$1] }) && 
			x.why == y.why
	} 
}

extension Demo: Hashable {
 	var hashValue: Int {
		return cool.hashValue ^ 
			what.hashValue ^ 
			whatIfIWantTo.reduce(0, { return 33 &* $0 ^ $1.hashValue }) ^ 
			why.hashValue
	} 
}
```

## What about Optionals? I don't see any Optionals.
Optionals are sort of handled by j2s. JSON doesn't have Optionals, so it's hard to map them over automatically. While parsing, if j2s is told to create the same `struct` multiple times, it considers any properties that don't exist in both models to be [Optional](http://swiftdoc.org/v3.0/type/Optional/).

`null`s are turned into `NSNull`.

## Oh.
Yeah. Usually happens in the case of an array of dictionaries. This json:
```json
{
  "foo": [
  {
    "bar": 42,
	"baz": true
  }, {
    "bar": 42,
	"gizmo": "raygun"
  }
  ]
}
```

will generate this Swift code:

```swift
public struct Demo {
	let foo: [Foo]

	init(_ dictionary: [String: Any]) {
		let foo = dictionary["foo"] as! [[String: Any]]
		self.foo = foo.flatMap { return Foo($0) }
	}
}

extension Demo: Equatable {
 	public static func ==(x: Demo, y: Demo) -> Bool {
		return x.foo.count == y.foo.count && 
				(0 ..< x.foo.count).reduce(false, { $0 || x.foo[$1] == y.foo[$1] })
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
	let gizmo: String?

	init(_ dictionary: [String: Any]) {
		self.bar = dictionary["bar"] as! Int
		self.baz = dictionary["baz"] as? Bool
		self.gizmo = dictionary["gizmo"] as? String
	}
}

extension Foo: Equatable {
 	public static func ==(x: Foo, y: Foo) -> Bool {
		return x.bar == y.bar && 
			x.baz == y.baz && 
			x.gizmo == y.gizmo
	} 
}

extension Foo: Hashable {
 	public var hashValue: Int {
		return bar.hashValue ^ 
			(baz?.hashValue ?? 0) ^ 
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

## Okay then
Before you go, remember that j2s code is released under a [2-Clause BSD License](LICENSE.md) and all contributions and project activity should be in line with our [Code of Conduct](CODE_OF_CONDUCT.md).
