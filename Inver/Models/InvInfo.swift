import Foundation
import AVFoundation

struct InvInfo {
    var number: String
    var date: String
    var random: String
    var untaxedSales: Int
    var totalSales: Int
    var buyerID: String
    var salerID: String
    var encrypt: String
    var otherInfo: String
    var numberOfProductKinds: Int
    var numberOfProducts: Int
    var encodingType: Int
    
    init?(metadataObject: AVMetadataMachineReadableCodeObject) {
        guard let sections = metadataObject.stringValue?.split(separator: ":"), sections.count >= 5,
            let section1 = sections.first, section1.count == 77 else {
            return nil
        }
        
        func hexToInt(string: String) -> Int? { Int(string, radix: 16) }
        
        let numberIndex = section1.index(section1.startIndex, offsetBy: 10)
        let dateIndex = section1.index(numberIndex, offsetBy: 7)
        let randomIndex = section1.index(dateIndex, offsetBy: 4)
        let untaxedSalesIndex = section1.index(randomIndex, offsetBy: 8)
        let totalSalesIndex = section1.index(untaxedSalesIndex, offsetBy: 8)
        let buyerIDIndex = section1.index(totalSalesIndex, offsetBy: 8)
        let salerIDIndex = section1.index(buyerIDIndex, offsetBy: 8)
        let encryptIndex = section1.index(salerIDIndex, offsetBy: 24)
        
        guard let untaxedSalesInt = hexToInt(string: String(section1[randomIndex..<untaxedSalesIndex])),
            let totalSalesInt = hexToInt(string: String(section1[untaxedSalesIndex..<totalSalesIndex])),
            let numberOfProductKindsInt = Int(String(sections[2])),
            let numberOfProductsInt = Int(String(sections[3])),
            let encodingTypeInt = Int(String(sections[4])) else { return nil }
        
        number       = String(section1[..<numberIndex])
        date         = String(section1[numberIndex..<dateIndex])
        random       = String(section1[dateIndex..<randomIndex])
        untaxedSales = untaxedSalesInt
        totalSales   = totalSalesInt
        buyerID      = String(section1[totalSalesIndex..<buyerIDIndex])
        salerID      = String(section1[buyerIDIndex..<salerIDIndex])
        encrypt      = String(section1[salerIDIndex..<encryptIndex])
        otherInfo    = String(sections[1])
        numberOfProductKinds = numberOfProductKindsInt
        numberOfProducts = numberOfProductsInt
        encodingType = encodingTypeInt
    }
    
}

struct InvProduct {
    
    init() {
        
    }
    
}
