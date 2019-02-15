//
//  PostFormWebViewController.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/8/3.
//

import Foundation
import WebKit
/*
public final class PostFormWebViewController: UIViewController {

    public var backAction: ResponseCompletion?
    
    public var willOpenURL: ((URL) -> Void)?
    
    private var backNavigation: WKNavigation?
    
    private var needLoadJSPOST = true

    private let configuration: WKWebViewConfiguration = WKWebViewConfiguration()
    
    private var webView: WKWebView!
    
    private let formProfile: PostFormProfile
    
    /// 进度条
    private var progressView: UIProgressView!
    
    public init(formProfile: PostFormProfile) {
        self.formProfile = formProfile
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.navigationDelegate = self
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.navigationDelegate = nil
    }
    
    private func setupViews() {
        
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = .white
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.loadHTMLString(formProfile.loadHTMLString, baseURL: formProfile.baseURL)
        view.addSubview(webView)
        
        progressView = UIProgressView()
        progressView.tintColor = .orange
        progressView.trackTintColor = .white
        view.addSubview(progressView)
        
        var back_nor_item: UIBarButtonItem?
        var close_nor_item: UIBarButtonItem?
        
        if let imagePath = Bundle.formAssetBundle.path(forResource: "icon_back@2x", ofType: "png", inDirectory: "Images") {
            let back_nor = UIImage(contentsOfFile: imagePath)
            back_nor_item = UIBarButtonItem(image: back_nor, style: .plain, target: self, action: #selector(goBack))
        }
        
        if let imagePath = Bundle.formAssetBundle.path(forResource: "icon_blackClose@2x", ofType: "png", inDirectory: "Images") {
            let back_nor = UIImage(contentsOfFile: imagePath)
            close_nor_item = UIBarButtonItem(image: back_nor, style: .plain, target: self, action: #selector(close))
        }
        
        var leftItems = Array<UIBarButtonItem>()
        
        back_nor_item.flatMap({ leftItems.append($0) })
        close_nor_item.flatMap({ leftItems.append($0) })

        navigationItem.leftBarButtonItems = leftItems
    }
    
    private func setupConstraints() {
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        var p_top: NSLayoutConstraint {
            if #available(iOS 11.0, *) {
                return makeConstraint(target: progressView, attr: .top, toItem: view.safeAreaLayoutGuide, attr: .top, offset: 0)
            } else {
                return makeConstraint(target: progressView, attr: .top, toItem: topLayoutGuide, attr: .bottom, offset: 0)
            }
        }
        
        let p_height = makeConstraint(target: progressView, attr: .height, offset: 3)
        let p_leading = makeConstraint(target: progressView, attr: .leading, toItem: view, offset: 0)
        let p_trailing = makeConstraint(target: progressView, attr: .trailing, toItem: view, offset: 0)
        
        let w_bottom = makeConstraint(target: webView, attr: .bottom, toItem: view, offset: 0)
        let w_top = makeConstraint(target: webView, attr: .top, toItem: progressView, attr: .bottom, offset: 0)
        let w_leading = makeConstraint(target: webView, attr: .leading, toItem: view, offset: 0)
        let w_trailing = makeConstraint(target: webView, attr: .trailing, toItem: view, offset: 0)
        
        view.addConstraints([p_top, p_height, p_leading, p_trailing, w_top, w_bottom, w_trailing, w_leading])
        
    }
    
    private func makeConstraint(target: UIView, attr targetAttr: NSLayoutConstraint.Attribute, toItem: Any? = nil, attr toAttr: NSLayoutConstraint.Attribute? = nil, offset: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: target, attribute: targetAttr, relatedBy: .equal, toItem: toItem, attribute: toAttr ?? targetAttr, multiplier: 1.0, constant: offset)
    }
    
    /// 关闭操作
    @objc
    public func close() {
        backAction?(PayResponse())
        navigationController?.popViewController(animated: true)
    }
    
    
    /// 后退操作
    @objc
    public func goBack() {
        if webView.canGoBack {
            backNavigation = webView.goBack()
            webView.reload()
        } else {
            backAction?(PayResponse())
            navigationController?.popViewController(animated: true)
        }
    }
    
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            progressView.alpha = 1.0
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            if webView.estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                    self.progressView.alpha = 0.0
                }, completion: { (finfished: Bool) in
                    self.progressView.setProgress(0.0, animated: false)
                })
            }
        }
    }
    
//    private func loadJSPOST() {
//        // 获取JS路径
//        let path = Bundle.main.path(forResource: "JSPOST", ofType: "html")
//        // 获得html内容
//        do {
//            let html = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
//            // 加载js
//            webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
//        } catch { }
//    }
    
    
    /// 调用JS发送POST请求
    private func postRequestWithJS() {
        guard let js = formProfile.javeScript, js.isEmpty == false else {
            return
        }
        // 调用JS代码
        webView.evaluateJavaScript(js) { (_, error) in
            if error == nil {
                //printLogDebug("----- post 请求成功")
            }
        }
    }
}

extension PostFormWebViewController: WKNavigationDelegate {
    
    // 开始加载时
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
    }
    
    /// 即将白屏
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
//        printLogDebug("------ 白屏了")
    }
    
    // 完成加载
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        printLogDebug("----- H5页面加载完成")
        if needLoadJSPOST {
            // 调用使用JS发送POST请求的方法
            postRequestWithJS()
            // 将Flag置为NO（后面就不需要加载了）
            needLoadJSPOST = false
        }
        //一网通的H5界面不支持goback，猜测原因可能是WKWebView的老问题post请求的body信息丢失，回退之后再做一次刷新暂时可以解决
        if let curNavigation = backNavigation, navigation == curNavigation {
            webView.reload()
            backNavigation = nil
        }
    }
    
    // 服务器开始请求的时候调用
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        if url.absoluteString == formProfile.returnURLString {
            self.navigationController?.popViewController(animated: true)
        }
        else if formProfile.openURLRole(url) {
            print(url)
            willOpenURL?(url)
        }
        
        decisionHandler(.allow)
    }
    
}

*/
