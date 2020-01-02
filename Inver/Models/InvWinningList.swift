import Foundation

struct InvWinningList: InvQueryable {
    
    enum Params: String {
        case invTerm
    }
    
    static var version: String { "0.2" }
    static var action: String { "QryWinningList" }
    
    var invoYm: String
    
    var superPrizeNo: String
    var spcPrizeNo: String
    var spcPrizeNo2: String
    var spcPrizeNo3: String
    
    var firstPrizeNo1: String
    var firstPrizeNo2: String
    var firstPrizeNo3: String
    var firstPrizeNo4: String
    var firstPrizeNo5: String
    var firstPrizeNo6: String
    var firstPrizeNo7: String
    var firstPrizeNo8: String
    var firstPrizeNo9: String
    var firstPrizeNo10: String
    
    var sixthPrizeNo1: String
    var sixthPrizeNo2: String
    var sixthPrizeNo3: String
    
    var superPrizeAmt: String
    var spcPrizeAmt: String
    var firstPrizeAmt: String
    var secondPrizeAmt: String
    var thirdPrizeAmt: String
    var fourthPrizeAmt: String
    var fifthPrizeAmt: String
    var sixthPrizeAmt: String
    var sixthPrizeNo4: String
    var sixthPrizeNo5: String
    var sixthPrizeNo6: String
    
}
