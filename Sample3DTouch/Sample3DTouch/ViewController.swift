//
//  ViewController.swift
//  Sample3DTouch
//
//  Created by sonson on 2016/09/04.
//  Copyright © 2016年 sonson. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UZTextViewDelegate, UIViewControllerPreviewingDelegate {

    @IBOutlet var textView: UZTextView! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        textView?.delegate = self
        textView?.scale = 1
        do {
            let data = try Data(contentsOf: Bundle.main.url(forResource: "data", withExtension: "html")!)
            let options: [String: Any] = [
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
            ]
            let attr = try NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
                attr.addAttribute(NSFontAttributeName,
                                  value: UIFont.systemFont(ofSize: 20),
                                  range: NSRange(location: 0, length: attr.length))
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
    
    func textView(_ textView: UZTextView, didLongTapLinkAttribute value: Any?) {
        if let attr = value as? [String: Any] {
            if let url = attr[NSLinkAttributeName] as? URL {
                let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
                sheet.addAction(
                    UIAlertAction(title: "Close", style: .cancel) { (action) in
                        sheet.dismiss(animated: true, completion: nil)
                    }
                )
                sheet.addAction(
                    UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        sheet.dismiss(animated: true, completion: nil)
                    }
                )
                sheet.addAction(
                    UIAlertAction(title: "Open", style: .default) { (action) in
                        let controller = WebViewController(nibName: nil, bundle: nil)
                        controller.url = url
                        let nav = UINavigationController(rootViewController: controller)
                        self.present(nav, animated: true, completion: nil)
                    }
                )
                sheet.addAction(
                    UIAlertAction(title: "Copy URL", style: .default) { (action) in
                        UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                        sheet.dismiss(animated: true, completion: nil)
                    }
                )
                present(sheet, animated: true, completion: nil)
            }
        }
    }
    
    func textView(_ textView: UZTextView, didClickLinkAttribute value: Any?) {
        if let attr = value as? [String: Any] {
            if let url = attr[NSLinkAttributeName] as? URL {
                let controller = WebViewController(nibName: nil, bundle: nil)
                controller.url = url
                let nav = UINavigationController(rootViewController: controller)
                self.present(nav, animated: true, completion: nil)
            }
        }
    }
    
    func selectionDidEnd(_ textView: UZTextView) {
    }
    
    func selectionDidBegin(_ textView: UZTextView) {
    }
    
    func didTapTextDoesNotIncludeLinkTextView(_ textView: UZTextView) {
    }
    
    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = textView?.attributes(at: locationInTextView) {
            if let url = attr[NSLinkAttributeName] as? URL,
                let value = attr[UZTextViewClickedRect] as? CGRect {
                return (url, value)
            }
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let locationInTextView = self.view.convert(location, to: textView)

        if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
            previewingContext.sourceRect = self.view.convert(rect, from: textView)
            let controller = WebViewController(nibName: nil, bundle: nil)
            controller.url = url
            return controller
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        let nav = UINavigationController(rootViewController: viewControllerToCommit)
        self.present(nav, animated: true, completion: nil)
    }
}
