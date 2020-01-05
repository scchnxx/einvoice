import Foundation
import UIKit
import RxSwift
import RxCocoa

fileprivate let baseURL = "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp"

protocol InvQueryable: Codable {
    associatedtype Parameters: Hashable & RawRepresentable & CaseIterable where Parameters.RawValue == String
    
    static var version: String { get }
    static var action: String { get }
}

enum InvQueryError: Error {
    case missingParameters
    case genURLError
    case queryError(InvResponse)
}

extension InvQueryable {
    
    fileprivate static func url(parameters: [Parameters: String]) throws -> URL {
        guard var components = URLComponents(string: baseURL) else { throw InvQueryError.genURLError }
        guard parameters.count == Parameters.allCases.count else { throw InvQueryError.missingParameters }
        
        components.queryItems = parameters.map { key, value in
            URLQueryItem(name: key.rawValue, value: value)
        }
        
        let appIDItem = URLQueryItem(name: "appID", value: InvAppID)
        let actionItem = URLQueryItem(name: "action", value: action)
        let verItem = URLQueryItem(name: "version", value: version)
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let uuidItem = URLQueryItem(name: "UUID", value: uuid)
        components.queryItems?.append(contentsOf: [verItem, appIDItem, actionItem, uuidItem])
        
        if let url = components.url {
            return url
        }
        
        throw InvQueryError.genURLError
    }
    
}

extension Reactive where Base == URLSession {
    
    func invQuery<T: InvQueryable>(_ type: T.Type, parameters: [T.Parameters: String]) -> Observable<T> {
        Observable.create { observer in
            let url: URL
            
            do {
                url = try type.url(parameters: parameters)
            } catch {
                observer.on(.error(error))
                return Disposables.create()
            }
            
            var request = URLRequest(url: url)
            request.setValue("content-type", forHTTPHeaderField: "application/x-www-form-urlencoded")
            request.httpMethod = "POST"
            
            let dataTaks = self.base.dataTask(with: request) { data, resp, error in
                guard let data = data else {
                    observer.on(.error(error ?? RxCocoaURLError.unknown))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(InvResponse.self, from: data)
                    
                    if response.success {
                        let object = try JSONDecoder().decode(type, from: data)
                        observer.on(.next(object))
                        observer.on(.completed)
                    } else {
                        observer.on(.error(InvQueryError.queryError(response)))
                    }
                } catch {
                    observer.on(.error(error))
                }
            }
            
            dataTaks.resume()
            
            return Disposables.create { dataTaks.cancel() }
        }
    }
    
}
