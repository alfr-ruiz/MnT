import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Binding var isShowing: Bool
    @ObservedObject var settings: Settings
    @Environment(\.colorScheme) var colorScheme
    @State private var currentColorScheme: ColorScheme?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    // Appearance Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appearance")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 4)
                            
                            Picker("Theme", selection: $settings.colorScheme) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 17))
                                    .tag(Settings.ColorSchemePreference.light)
                                
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 17))
                                    .tag(Settings.ColorSchemePreference.dark)
                                
                                Image(systemName: "iphone")
                                    .font(.system(size: 17))
                                    .tag(Settings.ColorSchemePreference.system)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Display Section
                    Section {
                        Toggle("Auto-Lock Off", isOn: $settings.autoLockDisabled)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            .font(.system(size: 17))
                            .padding(.vertical, 4)
                    } header: {
                        Text("Display")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                // Website Link
                VStack {
                    Spacer()
                    Link(destination: URL(string: "https://alfredorm.com")!) {
                        Text("alfredorm.com")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)
                }
                .frame(height: 60)
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: 
                Button(action: {
                    isShowing = false
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(minWidth: 44, minHeight: 44)
            )
        }
        .preferredColorScheme(settings.colorScheme == .system ? colorScheme :
            settings.colorScheme == .dark ? .dark : .light)
        .onChange(of: settings.colorScheme) { _ in
            // Force view update when color scheme changes
            currentColorScheme = settings.colorScheme == .system ? colorScheme :
                settings.colorScheme == .dark ? .dark : .light
        }
        .onChange(of: colorScheme) { newValue in
            // Force view update when system appearance changes
            if settings.colorScheme == .system {
                currentColorScheme = newValue
            }
        }
    }
} 