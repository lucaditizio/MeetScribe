import SwiftUI

/// Passive VIPER View: reads state from Presenter, forwards user actions to Presenter
public struct DeviceSettingsView: View {
    // MARK: - Properties
    
    /// Strong reference to Presenter (output)
    public var output: DeviceSettingsViewOutput
    
    /// State from Presenter (read-only, updated via Presenter)
    public var state: DeviceSettingsState
    
    // MARK: - Init
    
    public init(output: DeviceSettingsViewOutput) {
        self.output = output
        self.state = DeviceSettingsState()
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background
            Theme.obsidian
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Connection Status Card
                    connectionStatusCard
                    
                    // Device List Card
                    deviceListCard
                }
                .padding(Spacing.cardPadding)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            output.didTriggerViewReady()
        }
    }
    
    // MARK: - Connection Status Card
    
    private var connectionStatusCard: some View {
        VStack(spacing: Spacing.contentPadding) {
            // Header
            HStack {
                Text("Connection Status")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Status content
            HStack(spacing: 12) {
                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                // Status text
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
                
                // Disconnect button (only when connected)
                if isConnected {
                    Button {
                        output.didTapDisconnect()
                    } label: {
                        Text("Disconnect")
                            .font(.subheadline)
                            .foregroundColor(Theme.scribeRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.scribeRed.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(Spacing.cardPadding)
        .scribeCardStyle()
    }
    
    // MARK: - Device List Card
    
    private var deviceListCard: some View {
        VStack(spacing: Spacing.contentPadding) {
            // Header with Scan button
            HStack {
                Text("Available Devices")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    output.didTapScan()
                } label: {
                    HStack(spacing: 4) {
                        if state.isScanning {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text(state.isScanning ? "Scanning..." : "Scan")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.scribeRed)
                    .cornerRadius(8)
                }
                .disabled(state.isScanning)
            }
            
            // Device list
            if state.discoveredDevices.isEmpty {
                Text("No devices found")
                    .font(.subheadline)
                    .foregroundColor(Theme.accentGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(state.discoveredDevices) { device in
                        DeviceRow(
                            device: device,
                            onTap: {
                                output.didTapDevice(device)
                            }
                        )
                        
                        if device.id != state.discoveredDevices.last?.id {
                            Divider()
                                .background(Theme.accentGray.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(Spacing.cardPadding)
        .scribeCardStyle()
    }
    
    // MARK: - Status Helpers
    
    public var statusColor: Color {
        switch state.connectionState {
        case .connected:
            return .green
        case .connecting, .disconnecting:
            return .yellow
        case .disconnected:
            return Theme.accentGray
        }
    }
    
    public var statusText: String {
        switch state.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnecting:
            return "Disconnecting..."
        case .disconnected:
            return "Disconnected"
        }
    }
    
    public var connectedDeviceName: String? {
        if case .connected(let device) = state.connectionState {
            return device.name
        }
        return nil
    }
    
    public var isConnected: Bool {
        if case .connected = state.connectionState {
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
                // Mic icon
                Image(systemName: "mic.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accentGray)
                    .frame(width: 32)
                
                // Device name
                Text(device.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // RSSI badge
                rssiBadge
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.accentGray)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var rssiBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "wifi")
                .font(.caption2)
            Text("\(device.rssi)")
                .font(.caption2)
        }
        .foregroundColor(rssiColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(rssiColor.opacity(0.15))
        .cornerRadius(6)
    }
    
    private var rssiColor: Color {
        if device.rssi > -50 {
            return .green
        } else if device.rssi > -70 {
            return .yellow
        } else {
            return Theme.scribeRed
        }
    }
}