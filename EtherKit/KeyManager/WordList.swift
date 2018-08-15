//
//  WordList.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/1/18.
//

public struct WordList {
  public enum Language {
    public enum ChineseCharacterSet {
      case traditional
      case simplified
    }

    case chinese(ChineseCharacterSet)
    case english
    case french
    case italian
    case japanese
    case korean
    case spanish

    var fileName: String {
      switch self {
      case let .chinese(characterSet):
        return characterSet == .traditional ? "chinese_traditional" : "chinese_simplified"
      case .english:
        return "english"
      case .french:
        return "french"
      case .italian:
        return "italian"
      case .japanese:
        return "japanese"
      case .korean:
        return "korean"
      case .spanish:
        return "spanish"
      }
    }
  }

  public let language: Language

  public lazy var wordList: [String] = {
    let frameworkBundle = Bundle(for: EtherQuery.self)
    guard let frameworkBundleURL = frameworkBundle.resourceURL?.appendingPathComponent("WordLists.bundle"),
      let wordListPath = Bundle(url: frameworkBundleURL)?.path(forResource: language.fileName, ofType: "txt") else {
      fatalError("Issue locating BIP39 Word List Bundle.  This probably means there's some config issue with your app.")
    }

    // UNSAFE
    return try! String(contentsOfFile: wordListPath, encoding: .utf8)
      .components(separatedBy: "\n")
  }()

  public init(language: Language) {
    self.language = language
  }
}
