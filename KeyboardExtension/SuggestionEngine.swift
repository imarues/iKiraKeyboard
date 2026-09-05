import Foundation

final class SuggestionEngine {
    private let commonArabic = [
        "الله","والله","هلا","هلو","شلونك","شخبارك","تمام","زين","اي","لا","اني","انت","انتي","هو","هي","هذا","هاي","هذي","هناك","هنا","اليوم","باچر","هسه","بعد","قبل","اريد","اريده","اريدك","اكدر","نكدر","ممكن","شكرا","حبيبي","مرحبا","السلام","عليكم","صباح","الخير","مساء","وين","شنو","ليش","شلون","لان","اذا","بس","كلش","جدا","ممتاز","تماما","اوكي","راح","جاي","عندي","عندك","عليه","عليها","بيها","بيه","التطبيق","الكيبورد","الصورة","الترجمة","الحافظة","نسخ","ارسال"
    ]
    private let commonEnglish = [
        "the","to","and","you","is","it","that","for","of","in","this","with","on","are","I","your","have","not","be","can","we","my","what","how","why","where","when","hello","hey","thanks","thank","please","okay","good","great","today","tomorrow","now","later","keyboard","clipboard","translate","translation","screenshot","send","copy","paste"
    ]

    func suggestions(context: String, language: KeyboardLanguage, lexicon: [String], limit: Int = 3) -> [String] {
        let prefix = currentWord(in: context)
        guard !prefix.isEmpty else { return Array((language == .arabic ? commonArabic : commonEnglish).prefix(limit)) }
        let learned = WordLearningStore.shared.suggestions(prefix: prefix, limit: 8)
        let base = language == .arabic ? commonArabic : commonEnglish
        let candidates = learned + lexicon + base
        var seen = Set<String>()
        return candidates.filter {
            let match = $0.lowercased().hasPrefix(prefix.lowercased()) && $0.caseInsensitiveCompare(prefix) != .orderedSame
            return match && seen.insert($0.lowercased()).inserted
        }.sorted {
            if $0.count == $1.count { return $0.localizedCompare($1) == .orderedAscending }
            return $0.count < $1.count
        }.prefix(limit).map { $0 }
    }

    func currentWord(in context: String) -> String {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let parts = context.components(separatedBy: separators)
        return parts.last ?? ""
    }
}
