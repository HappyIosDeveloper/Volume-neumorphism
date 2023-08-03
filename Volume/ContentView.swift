//
//  ContentView.swift
//  Volume
//
//  Created by Ahmadreza on 7/31/23.
//

import SwiftUI

struct ContentView: View {
    
    @State var value: CGFloat = 0
    
    private let lightGradientColors = [.white, Color.gray.opacity(0.3)]
    private let darkGradientColors = [Color(.darkGray), .black]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Text(verbatim: Int(value).description)
                .padding(.bottom, 30)
                .animation(nil)
            Volume(currentValue: $value, circleWidth: 250, maxValue: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Gradient(colors: colorScheme == .dark ? darkGradientColors : lightGradientColors))
        .onChange(of: value) { newValue in
            print("value: ", newValue)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Volume: View {
    
    @Binding var currentValue: CGFloat
    var circleWidth: CGFloat
    var minValue: Double = 0
    var maxValue: Double = 100
    var minText: String = "Min"
    var maxText: String = "Max"
    var numberOfIndicators: Int = 10
    var indicatorSize: CGFloat = 17
    var indicatorColor: Color = .green
    @State private var angle: Double = 0
    @State private var scale: CGFloat = 1
    
    var body: some View {
        ZStack {
            MinMaxTexts()
            IndicatorsShadowView(radius: $currentValue, color: indicatorColor)
            Indicators(progress: $currentValue, radius: circleWidth, id: UUID().uuidString, color: indicatorColor)
            Group {
                CenterCircle(rotation: $angle)
                IndicatorCircle(circleWidth: circleWidth)
                    .padding([.top, .trailing], circleWidth / 4)
                    .transformEffect(CGAffineTransform(translationX: -50, y: -50)
                        .concatenating(CGAffineTransform(rotationAngle: CGFloat(angle * .pi / 180)))
                        .concatenating(CGAffineTransform(translationX: 50, y: 50)))
            }
            .scaleEffect(scale)
            Circle() // shadow
                .trim(from: 0, to: angle / 360) // < ----- conversion is wrong!
                .stroke(.green, lineWidth: 50)
                .rotationEffect(.degrees(-230))
                .mask {
                    Indicators(progress: $currentValue, radius: circleWidth, id: UUID().uuidString, color: indicatorColor)
                }
        }
        .frame(width: circleWidth, height: circleWidth)
        .gesture(DragGesture()
            .onChanged { value in
                withAnimation(.spring(response: 2)) {
                    scale = 0.99
                    var newValue = value.location.x
                    if newValue > 140 { // passed from center
                        newValue = max((value.location.y / 2) + value.location.x, newValue)
                    } else {
                        newValue = min((-value.location.y / 2) + value.location.x, newValue)
                    }
                    if (0...280) ~= newValue {
                        angle = newValue
                        currentValue = (angle/280) * 100
                    }
                }
            } .onEnded({ _ in
                withAnimation(.linear(duration: 0.3)) {
                    scale = 1
                }
            })
        )
    }
    
    struct Indicators: View {
        @Binding var progress: CGFloat
        @State var radius: Double
        var id: String
        var color: Color
        var font: UIFont = .systemFont(ofSize: 17)
        @State var letterWidths: [Int:Double] = [:]
        var numberOfIndicators: Int = 20
        var title: String {
            return Array(0...numberOfIndicators).compactMap({ _ in "|" }).joined()
        }
        var lettersOffset: [(offset: Int, element: Character)] {
            return Array(title.enumerated())
        }
        var geKerning: CGFloat {
            let total = (radius - (20/100) * radius)
            let chSize = title.first!.description.realSize(font: font).width
            return total / (CGFloat(numberOfIndicators) * chSize)
        }
        var body: some View {
            ZStack {
                ForEach(lettersOffset, id: \.offset) { index, letter in
                    VStack {
                        Text(String(letter))
                            .font(Font(font))
                            .foregroundColor(Color(uiColor: .lightGray.withAlphaComponent(0.5)))
                            .kerning(geKerning * 10)
                            .background(LetterWidthSize())
                            .onPreferenceChange(WidthLetterPreferenceKey.self, perform: { width in
                                letterWidths[index] = width
                            })
                        Spacer()
                    }
                    .rotationEffect(fetchAngle(at: index))
                }
            }
            .frame(width: radius, height: radius)
            .rotationEffect(.degrees(-145))
        }
        
        func fetchAngle(at letterPosition: Int) -> Angle {
            let times2pi: (Double) -> Double = { $0 * 2 * .pi }
            let circumference = times2pi(radius)
            let finalAngle = times2pi(letterWidths.filter{$0.key <= letterPosition}.map(\.value).reduce(0, +) / circumference)
            return .radians(finalAngle)
        }
        
        struct WidthLetterPreferenceKey: PreferenceKey {
            static var defaultValue: Double = 0
            static func reduce(value: inout Double, nextValue: () -> Double) {
                value = nextValue()
            }
        }
        
        struct LetterWidthSize: View {
            var body: some View {
                GeometryReader { geometry in // using this to get the width of EACH letter
                    Color.clear.preference(key: WidthLetterPreferenceKey.self, value: geometry.size.width * 2)
                }
            }
        }
    }
    
    struct IndicatorsShadowView: View {
        @Binding var radius: CGFloat
        var color: Color
        var width: CGFloat = 20
        @Environment(\.colorScheme) private var colorScheme
        var body: some View {
            ZStack {
                Group {
                    Circle() // shadow
                        .trim(from: 0, to: radius / 360) // < ----- conversion is wrong!
                        .stroke(color.opacity(0.2), lineWidth: width)
                        .blur(radius: 20)
                }
                .padding(10)
                .rotationEffect(.degrees(130))
                .animation(.spring(), value: radius)
            }
        }
    }
    
    struct MinMaxTexts: View {
        var minText: String = "Min"
        var maxText: String = "Max"
        var body: some View {
            VStack {
                Spacer()
                HStack {
                    Text(minText)
                    Spacer()
                    Text(maxText)
                }
                .foregroundColor(Color(.lightGray.withAlphaComponent(0.7)))
                .padding(.horizontal)
                .padding(.horizontal)
            }
        }
    }
    
    struct CenterCircle: View {
        
        @Binding var rotation: Double
        
        let mainGradient = Gradient(stops: [
            .init(color: .init(uiColor: #colorLiteral(red: 0.9273031354, green: 0.9446414709, blue: 0.9891976714, alpha: 1)), location: 0.2),
            .init(color: .init(uiColor: #colorLiteral(red: 0.8507085443, green: 0.8666146398, blue: 0.9074911475, alpha: 1)), location: 0.8)
        ])
        let borderGradient = Gradient(stops: [
            .init(color: .init(uiColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), location: 0),
            .init(color: .init(uiColor: #colorLiteral(red: 0.8993311524, green: 0.9161464572, blue: 0.959358871, alpha: 1)), location: 1)
        ])
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(.ellipticalGradient(borderGradient, center: .center, startRadiusFraction: 0, endRadiusFraction: 1))
                    .padding(25)
                Circle()
                    .fill(.ellipticalGradient(mainGradient, center: .center, startRadiusFraction: 0.0, endRadiusFraction: 1))
                    .padding()
                    .padding()
//                Image("knob")
//                    .resizable()
//                    .padding(20)
//                    .rotationEffect(.degrees(rotation))
//                    .animation(nil)
//                    .opacity(0.1)
            }
            .padding()
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 20)
            .shadow(color: Color.white.opacity(0.7), radius: 10, x: 0, y: -5)
        }
    }
    
    struct IndicatorCircle: View {
        var circleWidth: CGFloat
        var size: CGFloat {
            return circleWidth / 6
        }
        var body: some View {
            ZStack {
                Circle()
                    .fill(.white.blendMode(.multiply))
                    .overlay(
                        Circle()
                            .stroke(Color(.lightGray), lineWidth: 2)
                            .blur(radius: 2)
                            .offset(x: 0, y: 6)
                            .mask(Circle().fill(LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom)))
                    )
            }
            .frame(width: size, height: size)
        }
    }
}
