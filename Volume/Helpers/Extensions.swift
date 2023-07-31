//
//  Extensions.swift
//  Volume
//
//  Created by Ahmadreza on 7/31/23.
//

import SwiftUI

extension String {
    
    func realSize(font: UIFont) -> CGSize {
        return self.size(withAttributes:[.font: font])
    }
}
