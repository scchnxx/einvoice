import Foundation
import AVFoundation

struct Invoice {
    
    struct Info {
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
        
        fileprivate init?(components: [String]) {
            guard components.count == 5, components[0].count == 77 else { return nil }
            
            func hexToInt(string: String) -> Int? { Int(string, radix: 16) }
            
            let numberIndex = components[0].index(components[0].startIndex, offsetBy: 10)
            let dateIndex = components[0].index(numberIndex, offsetBy: 7)
            let randomIndex = components[0].index(dateIndex, offsetBy: 4)
            let untaxedSalesIndex = components[0].index(randomIndex, offsetBy: 8)
            let totalSalesIndex = components[0].index(untaxedSalesIndex, offsetBy: 8)
            let buyerIDIndex = components[0].index(totalSalesIndex, offsetBy: 8)
            let salerIDIndex = components[0].index(buyerIDIndex, offsetBy: 8)
            let encryptIndex = components[0].index(salerIDIndex, offsetBy: 24)
            
            guard let untaxedSalesInt = hexToInt(string: String(components[0][randomIndex..<untaxedSalesIndex])),
                let totalSalesInt = hexToInt(string: String(components[0][untaxedSalesIndex..<totalSalesIndex])),
                let numberOfProductKindsInt = Int(String(components[2])),
                let numberOfProductsInt = Int(String(components[3])),
                let encodingTypeInt = Int(String(components[4])) else { return nil }
            
            number       = String(components[0][..<numberIndex])
            date         = String(components[0][numberIndex..<dateIndex])
            random       = String(components[0][dateIndex..<randomIndex])
            untaxedSales = untaxedSalesInt
            totalSales   = totalSalesInt
            buyerID      = String(components[0][totalSalesIndex..<buyerIDIndex])
            salerID      = String(components[0][buyerIDIndex..<salerIDIndex])
            encrypt      = String(components[0][salerIDIndex..<encryptIndex])
            otherInfo    = String(components[1])
            numberOfProductKinds = numberOfProductKindsInt
            numberOfProducts = numberOfProductsInt
            encodingType = encodingTypeInt
        }
    }
    
    struct ProductDetail {
        var name: String
        var quantity: Int
        var price: Int
    }
    
    var invoiceInfo: Info
    var productDetails: [ProductDetail]
    
    init?(object1: AVMetadataMachineReadableCodeObject, object2: AVMetadataMachineReadableCodeObject) {
        guard let string1 = object1.stringValue, let string2 = object2.stringValue else { return nil }

        let strings = [string1, string2]
            .map { $0.split(separator: ":") }
            .map { $0.map(String.init) }
        
        guard let leftStrings = strings.first(where: { $0.count >= 5 && $0[0].count == 77 }),
            let rightStrings = strings.first(where: { $0.first?.hasPrefix("**") == true }) else { return nil }
        
        let infoStrings = [String](leftStrings[..<5])
        let right = rightStrings.count.isMultiple(of: 3) ? rightStrings : []
        let productStrings = (leftStrings[5...] + right).map({ $0.replacingOccurrences(of: "*", with: "") })
        
        guard let info = Info(components: infoStrings), productStrings.count.isMultiple(of: 3) else { return nil }
        
        invoiceInfo = info
        
        productDetails = stride(from: 0, to: productStrings.count, by: 3).reduce([ProductDetail]()) { result, index in
            guard let quantity = Int(productStrings[index + 1]), let price = Int(productStrings[index + 2]) else { return result }
            return result + [ProductDetail(name: productStrings[index], quantity: quantity, price: price)]
        }
        
        guard invoiceInfo.numberOfProducts == productDetails.count else { return nil }
    }
    
}
