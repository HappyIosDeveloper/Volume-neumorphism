//
//  Parallax.swift
//  Volume
//
//  Created by Ahmadreza on 8/2/23.
//

import SwiftUI
import CoreMotion

struct ParallaxMotionModifier: ViewModifier {
    
    @ObservedObject var manager: MotionManager
    var magnitude: Double
    
    func body(content: Content) -> some View {
        content
            .offset(x: CGFloat(manager.roll * magnitude), y: CGFloat(manager.pitch * magnitude))
    }
}

class MotionManager: ObservableObject {

    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    private var manager: CMMotionManager

    init() {
        self.manager = CMMotionManager()
        self.manager.deviceMotionUpdateInterval = 1/60
        self.manager.startDeviceMotionUpdates(to: .main) { (motionData, error) in
            guard error == nil else {
                print(error!)
                return
            }

            if let motionData = motionData {
                self.pitch = motionData.attitude.pitch
                self.roll = motionData.attitude.roll
            }
        }

    }
    
    private func setupParallax() {
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.05
            manager.startDeviceMotionUpdates(to: .main) { (data, error) in
                if let data = data {
                    let rotation = sin(data.gravity.x) * -60
                    let newVal = Float(rotation)
                    //                    print(newVal)
                    let angle:Float = newVal
                    let alpha: Float = angle / 360
                    let startPointX = powf(sinf(2 * Float.pi * ((alpha + 0.75) / 2)),2)
                    let startPointY = powf(sinf(2 * Float.pi * ((alpha + 0) / 2)),2)
                    let endPointX = powf(sinf(2 * Float.pi * ((alpha + 0.25) / 2)), 2)
                    let endPointY = powf(sinf(2 * Float.pi * ((alpha + 0.5) / 2)), 2)
                    DispatchQueue.main.async {
//                        self.parallaxGradientLayer.endPoint = CGPoint(x: CGFloat(endPointX),y: CGFloat(endPointY))
//                        self.parallaxGradientLayer.startPoint = CGPoint(x: CGFloat(startPointX), y: CGFloat(startPointY))
                    }
                }
            }
        }
    }
}


struct ParallaxMotionTestView: View {

    @ObservedObject var manager = MotionManager()
    
    var body: some View {
        Color.red
            .frame(width: 100, height: 100, alignment: .center)
            .modifier(ParallaxMotionModifier(manager: manager, magnitude: 10))
    }
}
