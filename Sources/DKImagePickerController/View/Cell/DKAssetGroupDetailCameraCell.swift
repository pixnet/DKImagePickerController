//
//  DKAssetGroupDetailCameraCell.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 07/12/2016.
//  Copyright © 2016 ZhangAo. All rights reserved.
//

import UIKit

class DKAssetGroupDetailCameraCell: DKAssetGroupDetailBaseCell {
    
    class override func cellReuseIdentifier() -> String {
        return "DKImageCameraIdentifier"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let cameraImageView = UIImageView(frame: self.bounds)
        cameraImageView.contentMode = .scaleToFill
        cameraImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cameraImageView.image = DKImagePickerControllerResource.cameraImage()
        let cameraX = (self.contentView.frame.width - 45) / 2
        let cameraY = (self.contentView.frame.height - 45) / 2
        cameraImageView.frame = CGRect(x: cameraX, y: cameraY, width: 45, height: 45)
        
        self.contentView.addSubview(cameraImageView)
        
        self.contentView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        self.contentView.accessibilityIdentifier = "DKImageCameraAccessibilityIdentifier"
        self.contentView.isAccessibilityElement = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
} /* DKAssetGroupDetailCameraCell */
