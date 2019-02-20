//
//  PostFormWebViewController.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/8/3.
//

import Foundation
import WebKit

protocol PostFormNavigationViewDelegate: class {
    func didBackTapped()
    func didCloseTapped()
}

class PostFormNavigationView: UIView {
    
    weak var delegate: PostFormNavigationViewDelegate?
    
    private var backBtn: UIButton?
    private var closeBtn: UIButton?
    var titleLab: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    func setupView() {
        
        if let imagePath = Bundle.formAssetBundle.path(forResource: "icon_back@2x", ofType: "png", inDirectory: "Images") {
            if let back_nor = UIImage(contentsOfFile: imagePath) {
                
                let backBtn = UIButton()
                backBtn.setImage(back_nor, for: .normal)
                backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
                addSubview(backBtn)
                
                self.backBtn = backBtn
            }
            
        }
        
        if let imagePath = Bundle.formAssetBundle.path(forResource: "icon_blackClose@2x", ofType: "png", inDirectory: "Images") {
            if let back_nor = UIImage(contentsOfFile: imagePath) {
                
                let closeBtn = UIButton()
                closeBtn.setImage(back_nor, for: .normal)
                closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
                addSubview(closeBtn)
                
                self.closeBtn = closeBtn
            }
            
        }
        
        let titleLab = UILabel()
        titleLab.textAlignment = .center
        titleLab.font = UIFont.boldSystemFont(ofSize: 18)
        titleLab.textColor = .black
        addSubview(titleLab)
        
        self.titleLab = titleLab
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLab.frame.size = CGSize(width: 200, height: 20)
        titleLab.center.x = bounds.midX
        titleLab.frame.origin.y = bounds.height - titleLab.bounds.height - 9
        
        backBtn?.frame.size = CGSize(width: 30, height: 30)
        backBtn?.frame.origin = CGPoint(x: 10, y: bounds.height - 30 - 4)
        
        closeBtn?.frame.size = CGSize(width: 30, height: 30)
        
        if let backBtn = backBtn {
            closeBtn?.frame.origin = CGPoint(x: backBtn.frame.maxX + 10, y: bounds.height - 30 - 4)
        }
        else {
            closeBtn?.frame.origin = CGPoint(x: 10, y: bounds.height - 30 - 4)
        }
    }
    
    @objc
    private func backTapped() {
        delegate?.didBackTapped()
    }
    
    @objc
    private func closeTapped() {
        delegate?.didCloseTapped()
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

public final class PostFormWebViewController: UIViewController {
    
    public typealias ResponseCompletion = () -> Void
    
    //初始化实现
    public var backAction: ResponseCompletion?
    
    public var loadHTMLString: String = ""
    public var baseURL: URL?
    public var returnURLString: String = ""
    public var javeScript: String?
    public var openURLRole: ((URL) -> Bool)!
    public var openURLCompletion: ((URL) -> Void)?
    public var navigationItemTitle: String = ""
    
    private var backNavigation: WKNavigation?
    private var webView: WKWebView!
    private var needLoadJSPOST = true
    private let configuration: WKWebViewConfiguration = WKWebViewConfiguration()
    /// 进度条
    private var progressView: UIProgressView!
    private var navigationView: PostFormNavigationView!
    
    private var isFirst: Bool = true
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear")
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirst {
            isFirst = false
            
            let navigationRect = CGRect(x: 0, y: 0, width: view.bounds.width, height: iPhoneXTopInset + 64)
            navigationView.frame = navigationRect
            
            let progressRect = CGRect(x: 0, y: navigationRect.maxY, width: view.bounds.width, height: 3)
            progressView.frame = progressRect
            
            let webViewRect = CGRect(x: 0, y: progressRect.maxY, width: view.bounds.width, height: view.bounds.height - progressRect.maxY )
            webView.frame = webViewRect
            
        }
        
    }
    
    private func setupViews() {
        
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = .white
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.loadHTMLString(loadHTMLString, baseURL: baseURL)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.init(red: 247/255.0, green: 247/255.0, blue: 247/255.0, alpha: 1)
        view.addSubview(webView)
        
        progressView = UIProgressView()
        progressView.tintColor = .orange
        progressView.trackTintColor = .white
        view.addSubview(progressView)
        
        navigationView = PostFormNavigationView(frame: .zero)
        navigationView.backgroundColor = .white
        navigationView.delegate = self
        navigationView.titleLab.text = navigationItemTitle
        view.addSubview(navigationView)
        
    }
    
    deinit {
        print("已经释放")
    }
    
    public func free() {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.navigationDelegate = nil
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
    
    /// 调用JS发送POST请求
    private func postRequestWithJS() {
        guard let js = javeScript, js.isEmpty == false else {
            return
        }
        // 调用JS代码
        webView.evaluateJavaScript(js) { (_, error) in
            if error == nil {
                //printLogDebug("----- post 请求成功")
            }
        }
    }
    
    private var iPhoneXTopInset: CGFloat {
        if #available(iOS 11, *) {
            guard UIScreen.main.nativeBounds.height == 2436 else { return 0 }
            return view.safeAreaInsets.top
        }
        return 0
    }
}

extension PostFormWebViewController: PostFormNavigationViewDelegate {
    func didBackTapped() {
        if webView.canGoBack {
            backNavigation = webView.goBack()
            webView.reload()
        } else {
            backAction?()
        }
    }
    
    func didCloseTapped() {
        backAction?()
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
        
        if url.absoluteString == returnURLString {
            self.backAction?()
        }
        else if openURLRole(url) {
            openURLCompletion?(url)
        }
        
        decisionHandler(.allow)
    }
    
}

