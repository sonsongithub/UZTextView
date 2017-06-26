//
//  SampleCell.swift
//  UZTextView
//
//  Created by sonson on 2017/03/29.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit
import UZTextView

class SampleCell: UITableViewCell {
    let textView = UZTextView(frame: .zero)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.addSubview(textView)
        
        let views: [String: UIView] = [
            "contentView": self.contentView,
            "textView": textView
        ]
        
        textView.backgroundColor = .white
        
        textView.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addConstraints (
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[textView]-8-|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
        )
        self.contentView.addConstraints (
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[textView]-8-|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
        )
        
        
    }
}
