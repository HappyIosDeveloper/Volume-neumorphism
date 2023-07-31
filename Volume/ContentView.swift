//
//  ContentView.swift
//  Volume
//
//  Created by Ahmadreza on 7/31/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Volume(circleWidth: 250)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//  250     21.8        20        60
// width   kerning  characters  ch size
// the (20/100) * width = total | final - total / (chars * chSize) = space


struct Volume: View {
    
    var circleWidth: CGFloat
    var minValue: Double = 0
    var maxValue: Double = 100
    var minText: String = "Min"
    var maxText: String = "Max"
    var numberOfIndicators: Int = 10
    var indicatorSize: CGFloat = 17

    var body: some View {
        ZStack {
            Indicators(radius: circleWidth)
            MinMaxTexts()
            CenterCircle()
            IndicatorCircle()
        }
        .frame(width: circleWidth, height: circleWidth)
    }
    
    struct Indicators: View {
        var radius: Double
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
                            .foregroundColor(Color(uiColor: .lightGray))
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
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.horizontal)
            }
        }
    }
    
    struct CenterCircle: View {
        
        let gradient = Gradient(stops:
                                    [.init(color: .white, location: 0.2),
                                     .init(color: .white, location: 0.6),
                                     .init(color: .gray, location: 0.8)
                                    ])

        
        var body: some View {
            ZStack {
                Circle()
                    .fill(.ellipticalGradient(gradient, center: .center, startRadiusFraction: 0.1, endRadiusFraction: 0.6))
                    .padding()
                    .padding()
            }
        }
    }
    
    struct IndicatorCircle: View {
        var body: some View {
            ZStack {
            }
        }
    }
}
