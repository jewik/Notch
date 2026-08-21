import SwiftUI

struct AudioSwitcherView: View {
    
    @Environment(AppContainer.self)
    private var appContainer
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    private var viewModel: AudioDeviceViewModel {
        appContainer.audioViewModel
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            
            // ЛЕВАЯ КОЛОНКА: АКТИВНЫЕ ВЫХОДЫ
            VStack(alignment: .leading, spacing: 12) {
                Text("Output")
                                    .font(.system(size: ui(20), weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: ui(2)) {
                        ForEach(viewModel.activeDevices) { device in
                            let isActive = device.id == viewModel.activeDeviceID
                            
                            
                            NotchButton(
                                systemName: device.type.iconName,
                                title: device.name,
                                color: .white,
                                bgSize: CGSize(width: ui(120), height: ui(26)),
                                textSize: ui(14),
                                isActive: isActive,
                                action: {viewModel.selectActiveDevice(device)}
                            )
                            
//                            Button(action: {
//                                viewModel.selectActiveDevice(device)
//                            }) {
//                                HStack {
//                                    Image(systemName: device.type.iconName)
//                                        .frame(width: 20)
//                                    Text(device.name)
//                                        .lineLimit(1)
//                                    Spacer()
//                                    if isActive {
//                                        Image(systemName: "checkmark.circle.fill")
//                                            .foregroundColor(.white)
//                                    }
//                                }
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 10)
//                                .background(isActive ? Color.accentColor : Color(NSColor.controlBackgroundColor))
//                                .foregroundColor(isActive ? .white : .primary)
//                                .cornerRadius(8)
//                            }
//                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
            .frame(maxWidth: .infinity)
            
            // ПРАВАЯ КОЛОНКА: ОТКЛЮЧЕННЫЕ ЗАПОМНЕННЫЕ BLUETOOTH ДЕВАЙСЫ
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Bluetooth")
                        .font(.system(size: ui(20), weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    
                    if viewModel.isConnectingBluetooth {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: ui(2)) {
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
                                    bgSize: CGSize(width: ui(120), height: ui(26)),
                                    textSize: ui(14),
                                    isActive: false,
                                    disabled: viewModel.isConnectingBluetooth,
                                    action: {viewModel.connectBluetoothDevice(btDevice)}
                                )
                                
//                                Button(action: {
//                                    viewModel.connectBluetoothDevice(btDevice)
//                                }) {
//                                    HStack {
//                                        Image(systemName: "beats.headphones")
//                                            .frame(width: 20)
//                                            .opacity(0.6)
//                                        Text(btDevice.name)
//                                            .lineLimit(1)
//                                        Spacer()
//                                        Image(systemName: "cable.connector.slash")
//                                            .font(.caption)
//                                            .foregroundColor(.gray)
//                                    }
//                                    .padding(.horizontal, 12)
//                                    .padding(.vertical, 10)
//                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
//                                    .cornerRadius(8)
//                                }
//                                .buttonStyle(.plain)
//                                .disabled(viewModel.isConnectingBluetooth)
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(ui(14))
        .frame(width: 300, height: 150)
    }
}







#Preview {

    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)
        
        AudioSwitcherView()
            .environment(AppContainer())
            .background(Color.blue.opacity(0.2))


    }
    .frame(width: 300, height: 150)
    .frame(width: 400, height: 300, alignment: .top)
}
