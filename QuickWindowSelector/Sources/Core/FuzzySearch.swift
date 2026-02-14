import Foundation

struct FuzzySearch {
    static func score(query: String, target: String) -> Int {
        guard !query.isEmpty else { return 100 }
        
        let queryLower = query.lowercased()
        let targetLower = target.lowercased()
        
        guard targetLower.contains(queryLower) else {
            return 0
        }
        
        if targetLower == queryLower {
            return 1000
        }
        
        if targetLower.hasPrefix(queryLower) {
            return 900 + (1000 - target.count)
        }
        
        var score = 500
        var queryIndex = queryLower.startIndex
        var lastMatchIndex = targetLower.startIndex
        var consecutiveBonus = 0
        
        for (index, char) in targetLower.enumerated() {
            let targetIndex = targetLower.index(targetLower.startIndex, offsetBy: index)
            
            if queryIndex < queryLower.endIndex && char == queryLower[queryIndex] {
                score += 10
                
                if targetIndex == targetLower.startIndex {
                    score += 50
                } else if lastMatchIndex == targetLower.index(before: targetIndex) {
                    consecutiveBonus += 5
                    score += consecutiveBonus
                } else {
                    consecutiveBonus = 0
                }
                
                lastMatchIndex = targetIndex
                queryIndex = queryLower.index(after: queryIndex)
            }
        }
        
        if queryIndex == queryLower.endIndex {
            return score
        }
        
        return 0
    }
    
    static func search(query: String, in windows: [WindowInfo]) -> [WindowInfo] {
        if query.isEmpty {
            return windows
        }
        
        return windows
            .map { window -> (WindowInfo, Int) in
                let titleScore = score(query: query, target: window.displayTitle)
                let ownerScore = score(query: query, target: window.ownerName) / 2
                let totalScore = max(titleScore, ownerScore)
                return (window, totalScore)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}
