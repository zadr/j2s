## What's this?
`j2s` is a macOS app that converts [`JSON`](https://en.wikipedia.org/wiki/JSON) dictionaries into [Swift](https://swift.org) `struct`s.

![Screenshot](Screenshot.png?raw=true)

## That's it? Can I make it do anything else?
No, yeah, that's it. You give `j2s` a `json` file, and it gives you Swift `struct`s. You can pick if it outputs to one file or a _n_ files for _n_ `struct`s.

If you want to make it do anything else, you'll have to write some more code. I'll probably accept pull requests, but, you should probably look into other tools like [Sourcery](https://github.com/krzysztofzablocki/Sourcery) instead.

## Codable-compliant `struct`s, right?
Yup.

## Cool
Yeah. `j2s` will also convert `snake_case_key_names` into `camelCasePropertyNames`, and if you have a key where the value is an array of of dictionaries, the key name will be — naively — [depluralized](https://github.com/zadr/j2s/blob/main/j2s/StringTransformations.swift#L14) (exact line of code may change, but look around there for the algorithm).

And, if your `JSON` value is a string that's secretly a `Date` in a format that `j2s` understands (Currently: `ISO8601`), the generated code will use the correct (`Date`) type.

Also, an integer like `5` is an `Int` and a floating point number like `5.0` is a `Double`. Because, you know, thats how these things should work.

## What version of Swift does this target?
`j2s.xcodeproj` requires Swift 4 (Xcode 9 or greater) to build. The code it outputs requires Swift 4. If you need Swift 3 support, try looking back in commit history for an older version.

## What's the generated code look like?

`j2s` can take in the following `JSON`:

```json
{
  "outer" : true,
  "nested" : {
    "what_if_i_want_to" : [
      "boogie? wouldn't dream of stopping you"
    ],
    "when" : "2017-06-27T17:58:28+00:00",
    "cool" : true
  }
}
```

and turn it into Swift code that looks like this:

```swift
public struct Root: Codable {
	public let nested: Nested
	public let outer: Bool

	public struct Nested: Codable {
		public let cool: Bool
		public let whatIfIWantTo: [String]
		public let when: Date

		private enum CodingKeys: String, CodingKey {
			case cool
			case what_if_i_want_to = "whatIfIWantTo"
			case when
		}
	}

// MARK: -

extension Root.Nested {
	public static func create(with data: Data) -> Root.Nested  {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder.decode(Root.Nested.self, from: data)
	}

	public static func create(with data: Data) -> [Root.Nested]  {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder.decode([Root.Nested].self, from: data)
	}
}

// MARK: -

extension Root {
	public static func create(with data: Data) -> Root  {
		return JSONDecoder().decode(Root.self, from: data)
	}

	public static func create(with data: Data) -> [Root]  {
		return JSONDecoder().decode([Root].self, from: data)
	}
}
```

## What about `Optional`s? I heard Swift has `Optional`s, but, I don't see any `Optional`s.
`Optional`s are sort of handled by `j2s`. `JSON` doesn't have `Optional`s, so it's hard to map them over automatically.

While parsing, if `j2s` is told to create the same `struct` multiple times, it considers any properties that don't exist in both models to be [`Optional`](http://swiftdoc.org/v3.0/type/Optional/).

The same is also true for properties that show up as `null` and as a `Type`.

`null`s are turned into `Any?`.

## Oh.
Yeah. Usually happens in the case of an array of dictionaries. This `JSON`:

```json
{
  "outer" : true,
  "nested" : {
    "im_going_to_" : [
      "type? sure, but uncheck the \"Pretty-Print JSON\" box down there --v",
      "boogie? wouldn't dream of stopping you"
    ],
    "what" : "paste json here"
  }
}
```

will generate this Swift code:

```swift
public struct Demo: Codable {
	public let nested: Nested
	public let outer: Bool

	public struct Nested: Codable {
		public let imGoingTo: [String]
		public let what: String

		private enum CodingKeys: String, CodingKey {
			case im_going_to_ = "imGoingTo"
			case what
		}
	}

	private enum CodingKeys: String, CodingKey {
		case nested
		case outer
	}
}

// MARK: -

public extension Nested {
	public static func create(with data: Data) throws -> Nested  {
		return try JSONDecoder().decode(Nested.self, from: data)
	}

	public static func create(with data: Data) throws -> [Nested]  {
		return try JSONDecoder().decode([Nested].self, from: data)
	}
}

// MARK: -

public extension Demo {
	public static func create(with data: Data) throws -> Demo  {
		return try JSONDecoder().decode(Demo.self, from: data)
	}

	public static func create(with data: Data) throws -> [Demo]  {
		return try JSONDecoder().decode([Demo].self, from: data)
	}
}
```

## Why build this and not use some other tool?
Seemed like a good idea. This was before `Codable` was a thing.

## Still hung up on depluralization? (Singularity?)
A `JSON` dictionary with a key named `potatoes`, where the value is a list of dictionaries will be given the Swift type `[Potato]`. Similarly, `soliloquies` becomes `[Soliloquy]`, `dwarves` and `[Dwarf]`, and so on. Depluralization is a giant `if` statement though, so while `indices` becomes `[Index]`, `matrices` incorrectly becomes `matrex`. If Anyone wanted to do some natural language processing to solve this, that would be cool.

## Okay then
Before you go, remember that `j2s` code is released under a [2-Clause BSD License](LICENSE.md) and all contributions and project activity should be in line with our [Code of Conduct](CODE_OF_CONDUCT.md).
