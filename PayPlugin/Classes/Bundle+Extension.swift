//
//  PayConfig.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

extension Bundle {
    
    static var formAssetBundle: Bundle {
        let podBundle = Bundle(for: PostFormWebViewController.self)
        
        guard let resourceBundleUrl = podBundle.url(forResource: "PayAssets", withExtension: "bundle") else {
            fatalError("资源Bundle的路径不对")
        }
        
        guard let resourceBundle = Bundle(url: resourceBundleUrl) else {
            fatalError("资源Bundle没有找到")
        }
        
        return resourceBundle
    }
}
