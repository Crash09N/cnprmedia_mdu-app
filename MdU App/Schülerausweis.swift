//
//  Schülerausweis.swift
//  MdU App
//
//  Created by Noah R on 24.02.25.
//

import SwiftUI
import PassKit

struct Schülerausweis: View {
    @State private var imageData: Data?
    
    var body: some View {
        VStack {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .padding()
            } else {
                Text("Loading image...")
                    .padding()
            }
            
            Text("Schülerausweis")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Spacer()
            
            Button(action: {
                addToWallet()
            }) {
                Text("Add to Wallet")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Schülerausweis")
        .onAppear {
            loadImage()
        }
    }
    
    func loadImage() {
        NetworkManager.shared.fetchImage { data in
            DispatchQueue.main.async {
                self.imageData = data
            }
        }
    }
    
    func addToWallet() {
        // Check if the device supports adding passes
        guard PKPassLibrary.isPassLibraryAvailable() else {
            print("Pass library is not available.")
            return
        }
        
        NetworkManager.shared.fetchPass { data in
            guard let data = data else {
                print("Failed to fetch pass data.")
                return
            }
            
            do {
                let pass = try PKPass(data: data)
                
                // Present the add pass view controller
                if let addPassVC = PKAddPassesViewController(pass: pass) {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(addPassVC, animated: true, completion: nil)
                    }
                } else {
                    print("Failed to create PKAddPassesViewController.")
                }
            } catch {
                print("Error loading pass: \(error)")
            }
        }
    }
}

struct Schülerausweis_Previews: PreviewProvider {
    static var previews: some View {
        Schülerausweis()
    }
}

