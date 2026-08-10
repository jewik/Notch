

import SwiftUI
import UniformTypeIdentifiers

// 6 points of width 300 UIs in total
struct AirDropView: View {

    @Environment(\.uiScale)
    private var scale
        
    @State var isDragging: Bool = false
    
    private var bgOpacity: Double {
        isDragging ? 0.3 : 0.2
    }
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: ui(30))
                .fill(Color.indigo.opacity(bgOpacity))
                .stroke(Color.indigo.opacity(bgOpacity), lineWidth: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack (spacing: ui(6)){
                Image(systemName: "airplayaudio").font(.system(size: ui(20)))
                Text("AirDrop")
                    .font(.system(size: ui(20)))
            }
        }
        .padding(ui(10))
        .frame(width: ui(500), height: ui(150), alignment: .leading)
        
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: $isDragging
        ) {
            providers in
            print("AirDrop share called")
            return AirDropService.share(providers)
        }
    }
}

#Preview {
    AirDropView()
        .background(Color.pink.opacity(0.1))
}
