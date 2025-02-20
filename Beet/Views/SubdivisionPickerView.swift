import SwiftUI

struct SubdivisionPickerView: View {
    @Binding var isShowing: Bool
    @Binding var subdivision: Settings.Subdivision
    let onSubdivisionChange: ((Settings.Subdivision) -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isShowing = false
                }
            
            VStack(spacing: 0) {
                Button(action: {
                    isShowing = false
                }) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity, maxHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .background(Color.gray.opacity(0.2))
                
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 0) {
                        ForEach(Settings.Subdivision.allCases, id: \.self) { sub in
                            Button(action: {
                                subdivision = sub
                                onSubdivisionChange?(sub)
                                isShowing = false
                            }) {
                                HStack {
                                    Image(systemName: subdivisionIcon(for: sub))
                                        .font(.title2)
                                        .frame(width: 40)
                                    
                                    Text(subdivisionText(for: sub))
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    if subdivision == sub {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding()
                                .contentShape(Rectangle())
                            }
                            .foregroundColor(.primary)
                            
                            if sub != Settings.Subdivision.allCases.last {
                                Divider()
                            }
                        }
                    }
                }
            }
            .frame(width: 250, height: 300)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(15)
            .padding()
        }
    }
    
    private func subdivisionIcon(for subdivision: Settings.Subdivision) -> String {
        switch subdivision {
        case .quarter: return "note.quarter"
        case .eighth: return "note.eighth"
        case .sixteenth: return "note.sixteenth"
        case .triplet: return "note.eighth.triplet"
        }
    }
    
    private func subdivisionText(for subdivision: Settings.Subdivision) -> String {
        switch subdivision {
        case .quarter: return "Quarter Note (♩)"
        case .eighth: return "Eighth Note (♪)"
        case .sixteenth: return "Sixteenth Note (𝅘𝅥𝅯)"
        case .triplet: return "Triplet (♪♪♪)"
        }
    }
} 