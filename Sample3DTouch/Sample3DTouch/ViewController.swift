//
//  ViewController.swift
//  Sample3DTouch
//
//  Created by sonson on 2016/09/04.
//  Copyright © 2016年 sonson. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UZTextViewDelegate, UIViewControllerPreviewingDelegate {

    @IBOutlet var textView: UZTextView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let data = try Data(contentsOf: Bundle.main.url(forResource: "data", withExtension: "html")!)
            let options: [String: Any] = [
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
            ]
            let attr = try NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
                attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 20), range: NSRange(location: 0, length: attr.length))
                textView?.attributedString = attr
            
        } catch {
            print(error)
        }
        
        self.registerForPreviewing(with: self, sourceView: self.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textView(_ textView: UZTextView!, didLongTapLinkAttribute value: Any!) {
        print(value)
    }
    
    func textView(_ textView: UZTextView!, didClickLinkAttribute value: Any!) {
        let sheet = UIAlertController(title: "a", message: "b", preferredStyle: .actionSheet)
        present(sheet, animated: true, completion: nil)
    }
    
    func selectionDidEnd(_ textView: UZTextView!) {
    }
    
    func selectionDidBegin(_ textView: UZTextView!) {
    }
    
    func didTapTextDoesNotIncludeLinkTextView(_ textView: UZTextView!) {
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        print(location)
        print("viewControllerForLocation")
        
        
        
        let controller = WebViewController(nibName: nil, bundle: nil)
        
        let locationInTextView = self.view.convert(location, to: textView)
        if let attr = textView?.attributes(at: locationInTextView) {
            if let url = attr["NSLink"] as? URL {
                controller.url = url
            }
        }
        
        return controller
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        let nav = UINavigationController(rootViewController: viewControllerToCommit)
        self.present(nav, animated: true, completion: nil)
    }
}

