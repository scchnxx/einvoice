import Foundation
import UIKit

fileprivate let baseURL = "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp"

protocol InvQueryable: Codable {
    associatedtype Params: Hashable & RawRepresentable where Params.RawValue == String
    
    static var version: String { get }
    static var action: String { get }
}

extension InvQueryable {
    
    fileprivate static func url(params: [Params: String]) -> URL? {
        guard var components = URLComponents(string: baseURL) else {
            return nil
        }
        
        components.queryItems = []
        
        for param in params {
            let item = URLQueryItem(name: param.key.rawValue, value: param.value)
            components.queryItems?.append(item)
        }
        
        let appIDItem = URLQueryItem(name: "appID", value: InvAppID)
        let actionItem = URLQueryItem(name: "action", value: action)
        let verItem = URLQueryItem(name: "version", value: version)
        components.queryItems?.append(contentsOf: [verItem, appIDItem, actionItem])
        
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let uuidItem = URLQueryItem(name: "UUID", value: uuid)
        components.queryItems?.append(uuidItem)
        
        return components.url
    }
    
}

extension URLRequest {
    
    static func invRequest<T: InvQueryable>(_ type: T.Type, parameters: [T.Params: String]) -> URLRequest? {
        guard let url = type.url(params: parameters) else { return nil }
        
        var req = URLRequest(url: url)
        req.setValue("content-type", forHTTPHeaderField: "application/x-www-form-urlencoded")
        req.httpMethod = "POST"
        
        return req
    }
    
}
