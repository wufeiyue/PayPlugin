//
//  PayResult.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

//MARK: - 支付结果
public enum PayResult<T> {
    case success(T)
    case failure(PayError)
    case progress(PaymentProgress)
}

public enum ResponseResult<T> {
    case success(T)
    case failure(PayError)
}

public enum PayError: Error {
    
    //支付宝客户端没有安装
    case alipayNeverInstall
    //微信客户端没有安装
    case wechatNeverInstall
    
    
    /// 余额不足
    case lackBalance
    
    /// 签名失败
    case signFailure
    
    /// 请求接口响应失败
    case responseFailure
    
    /// 解析失败
    case lossData
    
    /// 用户点击取消
    case userCancel
    
    /// 调用SDK发送失败
    case sentFailure
    
    /// 支付平台授权失败
    case authDeny
    
    /// 支付平台不支持
    case unsupport
    
    /// 支付平台主动取消
    case platformCancel
    
    /// 订单正在处理中
    case accepting
    
    /// 未知
    case unknow
    
    case custom(String?)
    
    //没有找到可用的客户端
    case notFountClient(PayClient)
    
}

extension PayError {
    
    //不可修复错误
    var isNotCanRepair: Bool {
        switch self {
        case .lossData, .sentFailure, .signFailure:
            return false
        default:
            return true
        }
    }
    
    //可以忽略的错误, 主要用于修复错误带来的问题, 在本地有支付结果, 请求服务器没有结果时, 用参考
    var isNegligible: Bool {
        switch self {
        case .sentFailure, .lossData, .responseFailure, .signFailure, .unknow:
            return true
        default:
            return false
        }
    }
}

extension PayError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .lackBalance:
            return "抱歉,您的余额不足"
        case .signFailure:
            return "签名失败, 请联系客服"
        case .lossData:
            return "数据丢失, 请稍后重试"
        case .userCancel:
            return "已经取消支付"
        case .sentFailure:
            return "调用SDK发送失败"
        case .authDeny:
            return "支付平台授权失败"
        case .unsupport:
            return "支付平台不支持"
        case .accepting:
            return "订单正在处理中"
        case .unknow:
            return "未知"
        case .responseFailure:
            return "接口响应失败, 请稍后重试"
        case .platformCancel:
            return "支付平台已取消"
        case .custom(let message):
            return message ?? ""
        case .notFountClient(let client):
            return "没有安装\(client.name)"
        case .alipayNeverInstall:
            return "没有安装支付宝"
        case .wechatNeverInstall:
            return "没有安装微信"
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .lackBalance:
            return "抱歉,您的余额不足"
        case .signFailure:
            return "签名失败, 请联系客服"
        case .lossData:
            return "数据丢失, 请稍后重试"
        case .userCancel:
            return "已经取消支付"
        case .sentFailure:
            return "调用SDK发送失败"
        case .authDeny:
            return "支付平台授权失败"
        case .unsupport:
            return "支付平台不支持"
        case .accepting:
            return "订单正在处理中"
        case .unknow:
            return "未知"
        case .responseFailure:
            return "接口响应失败, 请稍后重试"
        case .platformCancel:
            return "支付平台已取消"
        case .custom(let message):
            return message ?? ""
        case .notFountClient(let client):
            return "没有安装\(client.name)"
        case .alipayNeverInstall:
            return "没有安装支付宝"
        case .wechatNeverInstall:
            return "没有安装微信"
        }
    }
    
}
