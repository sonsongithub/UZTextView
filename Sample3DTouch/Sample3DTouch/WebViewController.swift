//
//  WebViewController.swift
//  Sample3DTouch
//
//  Created by sonson on 2016/09/04.
//  Copyright © 2016年 sonson. All rights reserved.
//

import Foundation
import WebKit

class WebViewController: UIViewController {
    let webView = WKWebView(frame: CGRect.zero)
    
    override var previewActionItems: [UIPreviewActionItem] {
        get {
            func previewActionForTitle(_ title: String, style: UIPreviewActionStyle = .default) -> UIPreviewAction {
                return UIPreviewAction(title: title, style: style) { previewAction, viewController in
                    print(title)
                }
            }
            
            let action1 = previewActionForTitle("Action1")
            let action2 = previewActionForTitle("Destructive Action", style: .destructive)
            
            let subAction1 = previewActionForTitle("Sub1")
            let subAction2 = previewActionForTitle("Sub2")
            let groupedActions = UIPreviewActionGroup(title: "Sub Actions", style: .default, actions: [subAction1, subAction2] )
            
            return [action1, action2, groupedActions]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["webView": webView]
        
        view.addConstraints (
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webView]-0-|", options: [], metrics: nil, views: views)
        )
        view.addConstraints (
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webView]-0-|", options: [], metrics: nil, views: views)
        )
        
        let bar = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(WebViewController.close(sender:)))
        self.navigationItem.rightBarButtonItem = bar
    }
    
    func close(sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var url: URL? = nil {
        didSet {
            if let aUrl = url {
                let request = URLRequest(url: aUrl)
                webView.load(request)
            }
        }
    }
}
