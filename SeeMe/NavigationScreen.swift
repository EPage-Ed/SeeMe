//
//  NavigationScreen.swift
//  SeeMe
//
//  Created by Ethan Saadia on 6/12/21.
//

import SwiftUI
import Combine

class SwiftUIState: ObservableObject {
    @Published var angle: Double = 0
    @Published var detectionState: DetectionState = .disabled
    
    enum DetectionState {
        /// The user hasn't provided a face yet
        case disabled
        /// No face detected in the current frame
        case searching
        /// Recognzied face in frame
        case tracking
    }
    
    var timer: Timer? = nil
    
    init() {
        self.timer = Timer(timeInterval: 3, repeats: true) { timer in
            withAnimation {
                self.angle += .pi/3
            }
        }
    }
}

struct NavigationScreen: View {
    @StateObject var appState = SwiftUIState()
    @State private var tap = false
    
    var symbolName: String {
        switch appState.detectionState {
        case .disabled:
            return "person.fill.viewfinder"
        case .searching:
            return "waveform.and.magnifyingglass"
        case .tracking:
            return "face.dashed"
        }
    }
    
    var body: some View {
        ZStack {
            ViewControllerRepresentable(tap: $tap)
                .edgesIgnoringSafeArea(.all)
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .foregroundColor(.clear)
                        Image(systemName: symbolName)
                            .font(.system(size: 200))
                            .foregroundColor(.white)
                            .rotationEffect(.radians(appState.angle))
                    }
                    Spacer()
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color(UIColor(red: 0, green: 0.75, blue: 0, alpha: 0.3)))
            .background(.clear)
        }
        .onTapGesture {
            tap = true
        }

    }
}


struct NavigationScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationScreen()
    }
}

struct ViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var tap: Bool
    
    class Coordinator: NSObject, ViewControllerDelegate {
        var parent: ViewControllerRepresentable
        
        init(_ parent: ViewControllerRepresentable) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        if tap {
            uiViewController.screenTappedSwiftUI()
            tap = false
        }
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let vc = storyboard.instantiateInitialViewController() as? ViewController {
            return vc
        } else {
            return ViewController()
        }
    }
}

protocol ViewControllerDelegate {
    /// Set angle in radians
    func setAngle(_ angle: Double)
}

extension ViewControllerDelegate {
    func setAngle(_ angle: Double) {
        
    }
}
