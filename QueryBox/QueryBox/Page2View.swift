import SwiftUI
import AVFoundation
import UIKit

struct Page2View: View {
    @Binding var textFromPage1: String
    @State var response: ChatGptResponse?
    
    @StateObject private var viewModel = Page2ViewModel()
    @State var isHidden = false
    @State private var isPaused = false
    let speechSynthesizer = AVSpeechSynthesizer()
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Query: \(textFromPage1)").foregroundStyle(.indigo)
            ScrollView {
                Text(response?.message ?? "")
                    .bold()
                    .font(.title3)
                Divider()
                if !isHidden {
                    ProgressView {
                        Text("Loading")
                            .foregroundColor(.indigo)
                            .bold()
                            .controlSize(.extraLarge)
                    }
                    .padding()
                }
            }
            
            HStack {
                Button(action: {
                    if speechSynthesizer.isSpeaking {
                        if isPaused {
                            speechSynthesizer.continueSpeaking()
                            isPaused = false
                        } else {
                            speechSynthesizer.pauseSpeaking(at: .immediate)
                            isPaused = true
                        }
                    }
                }) {
                    Text(isPaused ? "Resume" : "Pause")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()
                
                Button(action: {
                    speechSynthesizer.stopSpeaking(at: .immediate)
                    isPaused = false
                    presentationMode.wrappedValue.dismiss() // Navigate back to ContentView
                }) {
                    Text("Stop")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            setupAudioSession()
        }
        .task {
            do {
                response = try await viewModel.getResponseFromServer(textFromPage1: textFromPage1)
                isHidden = true
                if let responseText = response?.message {
                    speakText(responseText)
                }
            } catch ChatGptError.URLError {
                print("Error found in the URL")
            } catch ChatGptError.ResponseError {
                print("Server down")
            } catch {
                print("Something else", error)
            }
        }
    }
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func speakText(_ text: String) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        // Create an utterance with the recognized text
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Speak the text
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    Page2View(textFromPage1: .constant("Hello"))
}
