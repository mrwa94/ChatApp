//
//  imageModel.swift
//  ChatApp
//
//  Created by Ayman alsubhi on 06/03/1444 AH.
//

import Foundation
import UIKit

extension UIImage {
    
    var isportrate :Bool {return size.height > size.width}
    var isLAndScape : Bool {return size.width > size.height}
    var breadth : CGFloat {return min(size.width, size.height)}
    var breadthSize : CGSize {return CGSize (width: breadth, height: breadth) }
    var breathRect : CGRect {return CGRect (origin: .zero, size: breadthSize)}
    
    var circleMask : UIImage? {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        
        defer { UIGraphicsEndImageContext()}
        guard let cgImage = cgImage?.cropping(to:  CGRect(origin: CGPoint(x: isLAndScape ? floor((size.width - size.height) / 2) : 0 , y: isportrate ? floor((size.height - size.width) / 2 ) : 0 ) , size: breadthSize))
                                              
        else {  return nil }
        
        UIBezierPath(ovalIn: breathRect).addClip()
        UIImage(cgImage: cgImage).draw(in: breathRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
           
        
        
    }
    
    
}
