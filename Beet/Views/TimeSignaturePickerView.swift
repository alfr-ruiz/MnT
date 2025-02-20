import SwiftUI

struct TimeSignaturePickerView: View {
    @Binding var isShowing: Bool
    @Binding var numerator: Int
    @Binding var denominator: Int
    let onTimeSignatureChange: ((Int, Int) -> Void)?
    
    let numeratorValues = (1...16).map { String($0) }
    let denominatorValues = [1, 2, 4, 8].map { String($0) }
    
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
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: true) {
                        VStack(spacing: 0) {
                            ForEach(numeratorValues, id: \.self) { num in
                                ForEach(denominatorValues, id: \.self) { den in
                                    Button(action: {
                                        numerator = Int(num) ?? numerator
                                        denominator = Int(den) ?? denominator
                                        onTimeSignatureChange?(Int(num) ?? numerator, Int(den) ?? denominator)
                                        isShowing = false
                                    }) {
                                        HStack {
                                            Text("\(num)/\(den)")
                                                .font(.title2)
                                            
                                            Spacer()
                                            
                                            if numerator == Int(num) && denominator == Int(den) {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding()
                                        .contentShape(Rectangle())
                                    }
                                    .id("\(num)/\(den)")
                                    .foregroundColor(.primary)
                                    
                                    if !(num == numeratorValues.last && den == denominatorValues.last) {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        withAnimation {
                            proxy.scrollTo("\(numerator)/\(denominator)", anchor: .center)
                        }
                    }
                }
            }
            .frame(width: 250, height: 400)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(15)
            .padding()
        }
    }
} 