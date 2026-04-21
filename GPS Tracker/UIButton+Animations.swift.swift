//
//  UIButton+Animations.swift.swift
//  GPS Tracker
//
//  Created by Austin Baker on 20/4/2026.
//
import UIKit

extension UIButton {
    func animateTap() {
        UIView.animate(withDuration: 0.1,
            animations: {
                self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            },
            completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self.transform = CGAffineTransform.identity
                }
            })
    }
}
