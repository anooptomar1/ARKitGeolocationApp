//
//  Factories.swift
//  GeoARDJ
//
//  Created by Mac on 8/10/17.
//  Copyright © 2017 Mac. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

class Factories {

    static func updateLabel(infoLabel: UILabel, recognizer: UITapGestureRecognizer) -> Void {
        infoLabel.text = "Label loaded"
        infoLabel.font = UIFont.systemFont(ofSize: 12)
        infoLabel.numberOfLines = 4
        infoLabel.backgroundColor = UIColor(white: 0.4, alpha: 0.6)
        infoLabel.textColor = UIColor.white
        infoLabel.textAlignment = NSTextAlignment.center
        infoLabel.isUserInteractionEnabled =  true
        infoLabel.addGestureRecognizer(recognizer)

    }
    
    static func getTextNode(text: String) -> SCNNode {
        let sceneText = SCNText(string: text, extrusionDepth: 1)
        sceneText.font = UIFont (name: "San Francisco", size: 0.4)
        sceneText.firstMaterial!.diffuse.contents = UIColor.orange
        sceneText.firstMaterial!.specular.contents = UIColor.orange
        return SCNNode(geometry: sceneText)
    }
    
}
