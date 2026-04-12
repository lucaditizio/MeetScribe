import SwiftUI

public struct DeviceSettingsView: View {
    @Bindable var presenter: DeviceSettingsPresenter
    
    public init(presenter: DeviceSettingsPresenter) {
        self.presenter = presenter
    }
    
    public var body: some View {
        ZStack {
            Theme.obsidian
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    connectionStatusCard
                    deviceListCard
                }
                .padding(Spacing.cardPadding)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            presenter.didTriggerViewReady()
        }
    }
    
    // MARK: - Connection Status Card
    
    private var connectionStatusCard: some View {
        VStack(spacing: Spacing.contentPadding) {
            HStack {
                Text("Connection Status")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let deviceName = connectedDeviceName {
                        Text(deviceName)
                            .font(.caption)
                            .foregroundColor(Theme.accentGray)
                    }
                }
                
                Spacer()
                
                if isConnected {
                    Button {
                        presenter.didTapDisconnect()
                    } label: {
                        Text("Disconnect")
                            .font(.subheadline)
                            .foregroundColor(Theme.scribeRed)
                    }
                }
            }
        }
        .padding(Spacing.cardPadding)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(20)
    }
    
    // MARK: - Device List Card
    
    private var deviceListCard: some View {
        VStack(spacing: Spacing.contentPadding) {
            HStack {
                Text("Available Devices")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    presenter.didTapScan()
                } label: {
                    HStack(spacing: 4) {
                        if presenter.state.isScanning {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text(presenter.state.isScanning ? "Scanning..." : "Scan")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.scribeRed)
                    .cornerRadius(8)
                }
                .disabled(presenter.state.isScanning)
            }
            
            if presenter.state.discoveredDevices.isEmpty {
                Text("No devices found")
                    .font(.subheadline)
                    .foregroundColor(Theme.accentGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(presenter.state.discoveredDevices) { device in
                        DeviceRow(
                            device: device,
                            onTap: {
                                presenter.didTapDevice(device)
                            }
                        )
                        
                        if device.id != presenter.state.discoveredDevices.last?.id {
                            Divider()
                                .background(Theme.accentGray.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(Spacing.cardPadding)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(20)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch presenter.state.connectionState {
        case .disconnected:
            return Theme.accentGray
        case .connecting, .disconnecting:
            return .yellow
        case .connected:
            return .green
        }
    }
    
    private var statusText: String {
        switch presenter.state.connectionState {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        }
    }
    
    private var connectedDeviceName: String? {
        if case .connected(let device) = presenter.state.connectionState {
            return device.name
        }
        return nil
    }
    
    private var isConnected: Bool {
        if case .connected = presenter.state.connectionState {
            return true
        }
        return false
    }
}

// MARK: - Device Row

private struct DeviceRow: View {
    let device: DeviceSettingsBluetoothDevice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundColor(Theme.scribeRed)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("RSSI: \(device.rssi)")
                        .font(.caption)
                        .foregroundColor(Theme.accentGray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.accentGray)
            }
            .padding(.vertical, 12)
        }
    }
}