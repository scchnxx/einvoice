import Foundation

struct InvHeader: InvQueryable {
    
    enum Parameters: String, CaseIterable {
        /// Default Value: QRCode / Barcode
        case type
        case invNum
        /// Default Value: V2
        case generation
        // yyyy/MM/dd
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
