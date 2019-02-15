//
//  PayControlManager.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
/*
public class PayControlManager {
    
    var payPrepare = PayPrepareManager()
    
    var payControl: MultipartPayControl?
    
    lazy var formControl = PostFormControl()
    
    var queryResult: ((PayResponse?) -> Void)!
    
    private var progressCompletion: ((PaymentProgress) -> Void)!
    
    private var failureCompletion: ((PayError) -> Void)!
    
    public var listenedPayment = ListenedPaymentManager()
    
    public func config<T: PayProviderCustomizer>(provider: T, viewController: UIViewController) {
        
        guard payControl != nil else {
            progressCompletion(.prepare)
            queryResult(nil)
            return
        }
        
        start(provider: provider, viewController: viewController)
        
    }
    
    
    private func start<T: PayProviderCustomizer>(provider: T, viewController: UIViewController) {
        
        receiveObserver()
        
        if self.payPrepare.canOpenURL(client: provider.payClient) == false {
            if let payClient = provider.payClient, provider.openWebIfNotFoundClient == false {
                self.failureCompletion(.notFountClient(payClient))
                return
            }
        }
        
        willSign(provider: provider) { (paramsTyps) in
            switch paramsTyps.type {
            case .web:
                
                self.formControl.viewController = viewController
                
                self.formControl.payOrder(profile: paramsTyps.webProfile, result: { (response) in
                    self.check(response: response)
                })
                
                self.formControl.willOpenURL = {
                    return self.listenedPayment.openURLAndAddListened(with: $0)
                }
                
            case .client:
    
                self.payControl?.payType = provider.payType
                self.payControl?.payClient = provider.payClient
                self.payControl?.viewController = viewController
                
                self.payControl?.payOrder(profile: paramsTyps.clientProfile, result: { (response) in
                    self.check(response: response)
                })
                
                self.listenedPayment.add()
            }
        }
    }
    
    private func receiveObserver() {
        
        listenedPayment.completionHandler { object in
            
            if let url = object as? URL  {
                
                self.payControl?.processOrder(with: url, result: { response in
                    self.check(response: response)
                })
                
                return
            }
            
            self.check(response: nil)
        }
        
    }
    
    private func check(response: PayResponse?) {
        
        if let unwrappedError = response?.code, unwrappedError.isNotCanRepair {
            failureCompletion(unwrappedError)
            return
        }
        
        queryResult(response)
        
    }
 
    internal func progressResult(result: @escaping (PaymentProgress) -> Void) {
        
        self.progressCompletion = {
            
            switch $0 {
            case .prepare:
                self.payPrepare.isPaying = true
            case .completed:
                self.payPrepare.isPaying = false
            }
            
            result($0)
        }
    }
    
    internal func failureResult(result: @escaping (PayError) -> Void) {
        
        self.failureCompletion = {
            
            //TODO: 是否可修复
            if $0.isNotCanRepair {
                self.progressCompletion(.completed)
            }
            
            result($0)
            
        }
        
    }
    
    func removeListener() {
        listenedPayment.remove()
    }
}


extension PayControlManager {
    
    func willSign<T: PayProviderCustomizer>(provider: T, response: @escaping (PayParamsType) -> Void) {
        
        progressCompletion(.prepare)
        provider.sign { result in
            switch result {
            case .success(let params):
                response(params)
            case .failure(let error):
                self.failureCompletion(error)
            }
        }
    }
}
*/
