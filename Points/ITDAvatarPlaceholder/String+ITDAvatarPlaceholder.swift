//
//  String+ITDAvatarPlaceholder.swift
//  Pods
//
//  Created by Igor Kurylenko on 4/4/16.
//
//

extension String {
    public func toAvatarPlaceholderText(_ maxLettersCount: Int = 3) -> String {
        let maxLettersCount = maxLettersCount < 0 ? 0: maxLettersCount
        
        let text = self.firstLetters.uppercased()
        
        return text.characters.count > maxLettersCount ?
            text[text.startIndex..<text.characters.index(text.startIndex, offsetBy: maxLettersCount)] : text
    }
    
    var firstLetters: String {
        var result = String()        
        var shouldAddLetter = true
        
        unicodeScalars.forEach { ch in
            switch ch {
            case " ":
                shouldAddLetter = true
                
            case _ where shouldAddLetter && kLetterCharacterSet.contains(UnicodeScalar(ch.value)!):
                shouldAddLetter = false
                result.append(String(ch))
                
            default:
                break
            }
        }
        
        return result
    }
}
