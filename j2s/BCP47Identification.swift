import Foundation

// Pattern is based on https://gist.github.com/dwcaraway/7570091
// but is a lil more liberal than what it's based on, by accepting _ as a valid separator between tags
private let BCP47RegexPattern = "^(((([A-Za-z]{2,3}((-|_)([A-Za-z]{3}((-|_)[A-Za-z]{3}){0,2}))?)|[A-Za-z]{4}|[A-Za-z]{5,8})((-|_)([A-Za-z]{4}))?((-|_)([A-Za-z]{2}|[0-9]{3}))?((-|_)([A-Za-z0-9]{5,8}|[0-9][A-Za-z0-9]{3}))*((-|_)([0-9A-WY-Za-wy-z]((-|_)[A-Za-z0-9]{2,8})+))*((-|_)(x(-[A-Za-z0-9]{1,8})+))?)|(x((-|_)[A-Za-z0-9]{1,8})+)|((en(-|_)GB(-|_)oed|i(-|_)ami|i(-|_)bnn|i(-|_)default|i(-|_)enochian|i(-|_)hak|i(-|_)klingon|i(-|_)lux|i(-|_)mingo|i(-|_)navajo|i(-|_)pwn|i(-|_)tao|i(-|_)tay|i(-|_)tsu|sgn(-|_)BE(-|_)FR|sgn(-|_)BE(-|_)NL|sgn(-|_)CH(-|_)DE)|(art(-|_)lojban|cel(-|_)gaulish|no(-|_)bok|no(-|_)nyn|zh(-|_)guoyu|zh(-|_)hakka|zh(-|_)min|zh(-|_)min(-|_)nan|zh(-|_)xiang)))$"
private let BCP47Regex = try! NSRegularExpression(pattern: BCP47RegexPattern, options: .caseInsensitive)

extension String {
    var isBCP47Identifier: Bool {
        let range = NSMakeRange(0, self.utf8.count)
        return BCP47Regex.numberOfMatches(in: self, options: .reportCompletion, range: range) > 0
    }
}
