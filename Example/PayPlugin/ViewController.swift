//
//  ViewController.swift
//  PayPlugin
//
//  Created by eppeo on 11/07/2018.
//  Copyright (c) 2018 eppeo. All rights reserved.
//

import UIKit
import PayPlugin

class ViewController: UIViewController {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
/*
class AlipayProvider: Provider {
    
    var successFlag: Bool = true
    
    override func sign(result: @escaping (Result<Business, NSError>) -> Void) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            if self.successFlag {
                result(.success(.alipayClient(orderInfo: "orderInfo", scheme: "scheme")))
            }
            else {
                result(.failure(NSError(domain: "", code: -99, userInfo: nil)))
            }
        }
        
    }
    
}

*/
