//
//  JLampView.swift
//  UITests
//
//  Created by Usanin Ivan on 03.08.2026.
//



import SwiftUI

struct JLampView: View {
    
    @Environment(\.uiScale) private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        ZStack {
            
            HStack(spacing: 0) {

                VStack(spacing: ui(20)) {
                    
                    JLampSettingView()
                    JLampSettingView()
                    JLampSettingView()
                    
                }
                
                JLampImageView()
            }
        }
        .frame(width: ui(300), height: ui(150))
    }
}

#Preview{
    JLampView()
        .background(Color.green.opacity(0.1))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}

struct JLampImageView : View{
    
    @Environment(\.uiScale) private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ui(30))
                .fill(Color.clear.opacity(0.3))
                .frame(width: ui(130), height: ui(130))
//                .background(Color.blue.opacity(0.5))
            Image(systemName: "homepod.fill")
                .font(.system(size: ui(120), weight: .semibold))
        }
    }
}

struct JLampSettingView : View {
    
    @Environment(\.uiScale) private var scale
    
    var jLampViewModel = JLampViewModel()
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    
    var body: some View {
        
        HStack {
            
            Image(systemName: "sun.max.fill")
                .font(.system(size: ui(14), weight: .semibold))
            
//            GlassSlider(
//                value: $jLampViewModel.jBrightness
//            )  { newValue in
//                print("Brightness:", newValue)
//            }
        }
        .padding(.horizontal ,ui(10))

    }
}

struct GlassSlider: NSViewRepresentable {

    @Binding var value: Int

    var onChanged: ((Int) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSSlider {

        let slider = NSSlider(value: Double(value),
                              minValue: 0,
                              maxValue: 255,
                              target: context.coordinator,
                              action: #selector(Coordinator.valueChanged(_:)))

        // Remove tick marks
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false

        // Continuous updates while dragging
        slider.isContinuous = true

        // Optional
        slider.sliderType = .linear

        return slider
    }

    func updateNSView(_ slider: NSSlider, context: Context) {
        if Int(slider.doubleValue) != value {
            slider.doubleValue = Double(value)
        }
    }

    final class Coordinator: NSObject {

        let parent: GlassSlider

        init(_ parent: GlassSlider) {
            self.parent = parent
        }

        @objc
        func valueChanged(_ sender: NSSlider) {

            let value = Int(sender.doubleValue.rounded())

            parent.value = value
            parent.onChanged?(value)
        }
    }
}
