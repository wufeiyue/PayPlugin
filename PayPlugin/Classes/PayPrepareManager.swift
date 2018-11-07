//
//  PayPrepareManager.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

public struct PayPrepareManager {
    
    private var payClient: PayClient?
    
    public var isPaying: Bool = false
    
    public var openWebIfNotFoundClient: Bool = false
    
    public mutating func canOpenURL(client: PayClient?) -> Bool {
        
        guard let scheme = client?.config.canOpenString, let url = URL(string: scheme) else {
            return false
        }
        
        defer {
            self.payClient = client
        }
        
        #if DEBUG
            let schemesList = Bundle.main.infoDictionary?["LSApplicationQueriesSchemes"] as? Array<String>
            if let canOpenString = client?.config.canOpenString {
                if schemesList?.filter({ canOpenString.hasPrefix($0) }).isEmpty == true {
                    fatalError("还没有在info.plist中配置")
                }
            }
        #endif
        
        
        return UIApplication.shared.canOpenURL(url)
    }
    
    /// 检查终端回调的URL是否合法
    ///
    /// - Parameter url: 终端传输给App的url
    /// - Returns: 判断结果
    public func checkURL(fromClient url: URL) -> Bool {
        
        if let scheme = payClient?.config.openURLString {
            return url.host == scheme
        }
        else if isPaying {
            return true
        }
        
        return false
        
    }
    
    
    
}
