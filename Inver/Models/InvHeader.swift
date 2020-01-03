import Foundation

struct InvHeader: InvQueryable {
    
    enum Parameters: String, CaseIterable {
        case type
        case invNum
        case generation
        case invDate
    }
    
    static var version: String { "0.5" }
    static var action: String { "QryInvHeader" }
    
    var invNum: String
    var invDate: String
    var sellerName: String
    var invStatus: String
    var invPeriod: String
    var sellerAddress: String
    var buyerBan: String
    var currency: String
}
