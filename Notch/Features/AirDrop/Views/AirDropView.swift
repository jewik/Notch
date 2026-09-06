

import SwiftUI
import UniformTypeIdentifiers

// 6 points of width 300 UIs in total
struct AirDropNotificationView: View {
    @State var isDragging: Bool = false
    
    private var bgOpacity: Double {
        isDragging ? 0.3 : 0.2
    }
    
    var body: some View {
        
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.indigo.opacity(bgOpacity))
                .stroke(Color.indigo.opacity(bgOpacity), lineWidth: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack (spacing: 6){
                Image(systemName: "airplayaudio").font(.system(size: 20))
                Text("AirDrop")
                    .font(.system(size: 20))
            }
        }
        .padding(10)
        .frame(width: 500, height: 150, alignment: .center)
        
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
    AirDropNotificationView()
        .background(Color.pink.opacity(0.1))
}
