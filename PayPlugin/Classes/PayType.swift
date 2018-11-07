//
//  PayType.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

//MARK: - 支付类型
public enum PayType {
    case alipay(scheme: String)     //支付宝
    case weixin                     //微信
    case ywt                        //一网通
    case unionpay(scheme: String)   //银联
    case ccb                        //建行
    case unionRecharge              //银联充值
    case query                      //直接查询
}

public enum PayClient {
    
    /// 微信
    case weixin
    /// 支付宝
    case alipay
    /// 建行
    case ccb
    /// 银联
    case unionpay
    
}


