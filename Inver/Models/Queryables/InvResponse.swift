import Foundation

struct InvResponse: Codable {
    var version: String
    var code: Int
    var msg: String
    var success: Bool { code == 200 }
    
    enum CodingKeys: String, CodingKey {
        case version = "v"
        case code
        case msg
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        msg = try container.decode(String.self, forKey: .msg)
        if let code = try? container.decode(String.self, forKey: .code), let codeInt = Int(code) {
            self.code = codeInt
        } else if let code = try? container.decode(Int.self, forKey: .code) {
            self.code = code
        } else {
            throw DecodingError.dataCorruptedError(forKey: .code, in: container, debugDescription: "cannot find value for code")
        }
    }
}
