# PayPlugin

[![CI Status](https://img.shields.io/travis/eppeo/PayPlugin.svg?style=flat)](https://travis-ci.org/eppeo/PayPlugin)
[![Version](https://img.shields.io/cocoapods/v/PayPlugin.svg?style=flat)](https://cocoapods.org/pods/PayPlugin)
[![License](https://img.shields.io/cocoapods/l/PayPlugin.svg?style=flat)](https://cocoapods.org/pods/PayPlugin)
[![Platform](https://img.shields.io/cocoapods/p/PayPlugin.svg?style=flat)](https://cocoapods.org/pods/PayPlugin)

## 概述

![Design](https://raw.githubusercontent.com/wufeiyue/PayPlugin/master/Design.png)


目前支持的支付方式有:

- 支付宝
- 微信
- 银联
- 一网通
- 银联充值
- 钱包

## 配置

1.支付配置仅暴露一个接口:

```swift
/// 发起支付
///
/// - Parameters:
///   - target: 用于承载跳转的视图控制器
///   - provider: 提供支付签名的配置类
///   - result: 支付结果
func pay<T: PayBaseCustomizer>(target: UIViewController, provider: T, result: @escaping (PayResult<T.Model>) -> Void) 
```
2.用于AppDelegate中通知支付结果的OpenURL调用

```swift
/// 通知支付结果
///
/// - Parameter url: 第三方客户端回传过来的URL地址
func sendNotification(_ url: URL) 
```
## 演示

1.在ViewController中引用实例,支付结果在.success(let model)中回调, 其中model为接口 query(dict: _, payResult: _)调用以后, 返回的网络请求结果解析的Model类型, 比如model为下面AlipayModel的实例:

```swift

func viewDidLoad() {

    let provider = AlipayProvider()

    PayPlugin.default.pay(target: self, provider: provider) { (result) in
        switch result {
        case .success(let status):
            echo("支付成功:\(status)👍")
        case .progress(let progress):
            echo("当前进度:\(progress)")
            switch progress {
            case .prepare:
                //显示loading视图
                showLoading()
            case .completed:
                //隐藏loading视图
                hideLoading()
            }
        case .failure(let error):
            echo(error.localizedDescription)
        }
    }
}

```
2.新增一个支付签名配置的类, 需要遵守`PayProviderCustomizer`协议, 其中需要实现的方法如下:

```swift

struct AlipayModel {
    var amount: Double = 0.0
    var isPaySuccess: Bool = false
}

class AlipayProvider: PayProviderCustomizer {

    //验签接口解析成的数据模型, 完全自定义
    typealias Model = AlipayModel

    //配置的支付类型, 依据此PayType会自动匹配SDK中支付宝支付相关的API
    var payType: PayType {
        return .alipay(scheme: "约定的Scheme")
    }

    //签名配置类, 将签名结果回传给SDK中处理, 切记无论成功或失败都需要回传过去
    func sign(result: @escaping (ResponseResult<PayParamsType>) -> Void) {

        Alamofire.request(url: "https://****/alipay/sign", successCompletion: { dict in

            if let orderInfo = dict["orderInfo"] as? String {
                result(.success(.client(orderInfo: orderInfo)))
                return
            }

            result(.failure(.signFailure))

        }) { (error) in
            echo("请求失败: \(error)")
            result(.failure(.responseFailure))
        }
    }

    //验签接口配置, 如果dict为空, 就需要请求服务器去查询结果了, 一般不为空, dict为调用支付宝SDK验签接口返回的数据, 需保证Appdelegate中有配置, 此方法才会被调用
    func query(dict: [AnyHashable : Any?]?, payResult: @escaping (ResponseResult<Int>) -> Void) {
        Alamofire.request(url: "https://****/alipay/syncResult", successCompletion: {
            let model = AlipayModel(amount: $0.0, isPaySuccess: $0.1)
            payResult(.success(model))
        }) { (error) in
            echo("请求失败: \(error)")
            payResult(.failure(.signFailure))
        }
    }
}

```

2.在Appdelegate中完成配置:

```swift
func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    return openURLHandle(url: url)
}

// ios 9
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    return openURLHandle(url: url, options: options)
}

func openURLHandle(url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    PayPlugin.default.sendNotification(url)
    return true
}
```

## 安装

在项目中使用 `pod install`命令安装即可

```ruby
pod 'PayPlugin'
```

## 作者
@wufeiyue, 有问题请在主页上提issue, 谢谢使用.

## 证书认证

Component_Pay is available under the MIT license. See the LICENSE file for more info.
