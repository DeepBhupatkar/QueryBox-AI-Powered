//
//  ContentView.swift
//  QueryBox
//
//  Created by DEEP BHUPATKAR on 27/05/24.
//

import SwiftUI
import Vision
import PhotosUI

struct ContentView: View {
    
    @State private var uiImage: UIImage? = nil
    @State private var recognizedText: String = ""
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var navigateToPage2 = false
    @State private var isAnimating = false
       @State private var tagline = "QueryBox, Your personal AI assistant"
    
    
    
    
    var body: some View {
        NavigationView {
            VStack {
//                ScrollView {
//                    Text(recognizedText.isEmpty ? "Recognized text will appear here." : recognizedText)
//                        .padding()
//                }
//                .scrollDismissesKeyboard(.interactively)
//
                VStack{    Text("Welcome to QueryBox")
                        .font(.title)
                        .bold()
                        .foregroundColor(.indigo)
                        .padding()
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                        .onAppear {
                            isAnimating = true
                        }
                    
                    Spacer()
                    
                    Text("Your personal AI assistant")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                        .position(x: 180)
                }
                HStack {
                    PhotosPicker("Select an image", selection: $selectedItem, matching: .images)
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                                    uiImage = image
                                    recognizedText = ""
                                } else {
                                    print("Failed to load the image")
                                }
                            }
                        }
                        .buttonStyle(CustomButtonStyle(backgroundColor: .blue, foregroundColor: .white))
                                     
                    Button("Take a photo") {
                        self.showCamera.toggle()
                    }
                    .buttonStyle(CustomButtonStyle(backgroundColor: .blue, foregroundColor: .white))
                                  
                    .fullScreenCover(isPresented: self.$showCamera) {
                        AccessCameraView(selectedImage: self.$uiImage)
                    }
                }
                .padding()
                
                Button(action: {
                    if let image = self.uiImage {
                        processImage(uiImage: image)
                    }
                }) {
                    Label("Send To Query Box", systemImage: "play")
                        .padding(12)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(12)
                } .buttonStyle(CustomButtonStyle(backgroundColor: .blue, foregroundColor: .white))
                
                .padding()
                
                NavigationLink(destination: Page2View(textFromPage1: $recognizedText), isActive: $navigateToPage2) {
                    EmptyView()
                }
                .hidden()
            }
            .padding()
        }
    }
    
    func processImage(uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else {
            print("Failed To Convert to CGImage")
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        let request = VNRecognizeTextRequest { request, error in
            guard let results = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("Error Found while converting to VNRecognizedTextObservation")
                DispatchQueue.main.async {
                    recognizedText = "Something went wrong"
                }
                return
            }
            
            let outputText = results.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                recognizedText = outputText
                navigateToPage2 = true
            }
        }
        
        request.recognitionLevel = .accurate
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform([request])
            } catch {
                print("Failed to perform image request: \(error.localizedDescription)")
            }
        }
    }
}

struct AccessCameraView: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var isPresented
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var picker: AccessCameraView
        
        init(picker: AccessCameraView) {
            self.picker = picker
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                self.picker.selectedImage = selectedImage
            }
            self.picker.isPresented.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ContentView()
}



struct CustomButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
