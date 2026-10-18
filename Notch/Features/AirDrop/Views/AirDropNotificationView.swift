

import SwiftUI
import UniformTypeIdentifiers

// 6 points of width 300 UIs in total
struct AirDropNotificationView: PanelNotification {
    
    let id = UUID()
    let priority = 6 // Высокий приоритет
    let duration: TimeInterval = 5.0
    
        
    func makeView() -> AnyView {
        AnyView(AirDropNotificationContentView())
    }
}

struct AirDropNotificationContentView : View {
    
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
            .frame(width: 300, height: 100, alignment: .center)
        
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
    AirDropNotificationContentView()
        .background(Color.pink.opacity(0.1))
}
