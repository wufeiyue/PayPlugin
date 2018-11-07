//
//  MultipartPayResult.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

public class MultipartPayResult<T: PayProviderCustomizer> {
    
    let result: (PayResult<T.Model>) -> Void
    let provider: T!
    
    init(provider: T, result: @escaping (PayResult<T.Model>) -> Void) {
        self.result = result
        self.provider = provider
    }
    
    /*
     dict有值:
        客户端支付 -> 签名    跳转App -> 签名结果 -> 支付结果回调
     dict为空:
         分两种情况:
         1.客户端支付 -> 签名   网页支付  -> 查询结果  -> 支付结果回调
         2.查询结果 -> 支付结果回调
     */

    func verify(_ response: PayResponse?) {
        
        //本地同步通知支付成功
//        let isLocalSyncSuccessed: Bool = response.isPaySuccessed
        
        let payResult: ((ResponseResult<T.Model>) -> Void) = { [weak self] in
            
            //回调已完成, 可做关闭loading处理
            self?.result(.progress(.completed))
            self?.paymentDidCompleted()
            
            switch $0 {
            case .success(let message):
                self?.result(.success(message))
            case .failure(let error):
                //TODO: 将错误回调结果回调出去, 中间还可以做一些优化处理(ps: 修复错误)
//                if isLocalSyncSuccessed, error.isNegligible {
//                    self.result(.success())
//                }
                self?.result(.failure(error))
            }
            
        }
        
        provider.query(dict: response?.descriptor, payResult: payResult)
    }
    
    private func paymentDidCompleted() {
        
        
    }
    
}
