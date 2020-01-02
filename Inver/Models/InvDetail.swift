import Foundation

struct InvDetail: InvQueryable {
    
    enum Params: String {
        case type
        case invNum
        case generation
        case invTerm
        case invDate
        case encrypt
        case sellerID
        case randomNumber
    }
    
    static var version: String { "0.5" }
    static var action: String { "qryInvDetail" }
    
    struct Detail: Codable {
        var rowNum: String
        var description: String
        var quantity: String
        var unitPrice: String
        var amount: String
    }

    var invNum: String
    var invDate: String
    var sellerName: String
    var invStatus: String
    var invPeriod: String
    var sellerBan: String
    var sellerAddress: String
    var invoiceTime: String
    var buyerBan: String
    var currency: String
    var details: [Detail]
    
}
