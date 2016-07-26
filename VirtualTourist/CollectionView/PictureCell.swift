//
//  PictureCell.swift
//  VirtualTourist
//
//  Created by Max Saienko on 7/7/16.
//  Copyright © 2016 Max Saienko. All rights reserved.
//

import UIKit

class PictureCell: UICollectionViewCell {
    var spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    @IBOutlet var picture: UIImageView!
    @IBOutlet var loadIndicator: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.blackColor()
        self.layer.cornerRadius = 10.0
    }
    
    func startSpinner() {
        loadIndicator.startAnimating()
    }
    
    func stopSpinner() {
        loadIndicator.stopAnimating()
    }
}
