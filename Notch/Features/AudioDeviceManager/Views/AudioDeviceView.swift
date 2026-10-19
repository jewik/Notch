import SwiftUI

struct AudioSwitcherView: View {
    
    private var viewModel: AudioDeviceViewModel {
        AppContainer.shared.audioViewModel
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Output")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 2) {
                        ForEach(viewModel.activeDevices) { device in
                            let isActive = device.id == viewModel.activeDeviceID
                            
                            
                            NotchButton(
                                systemName: device.type.iconName,
                                title: device.name,
                                color: .white,
                                bgSize: CGSize(width: 120, height: 26),
                                textSize: 14,
                                isActive: isActive,
                                action: {viewModel.selectActiveDevice(device)}
                            )
                            
                            
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Bluetooth")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    
                    if viewModel.isConnectingBluetooth {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        if viewModel.rememberedBluetoothDevices.isEmpty {
                            Text("Нет доступных устройств")
                                .font(.callout)
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        } else {
                            ForEach(viewModel.rememberedBluetoothDevices) { btDevice in
                                
                                NotchButton(
                                    systemName: "beats.headphones",
                                    title: btDevice.name,
                                    color: .white,
                                    bgSize: CGSize(width: 120, height: 26),
                                    textSize: 14,
                                    isActive: false,
                                    disabled: viewModel.isConnectingBluetooth,
                                    action: {viewModel.connectBluetoothDevice(btDevice)}
                                )
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(width: 300, height: 150)
    }
}







#Preview {
    
    ZStack {
        PanelShape()
            .fill(.black)
        
        AudioSwitcherView()
//            .environment(AppContainer())
            .background(Color.blue.opacity(0.2))
        
        
    }
    .frame(width: 300, height: 150)
    .frame(width: 400, height: 300, alignment: .top)
}
