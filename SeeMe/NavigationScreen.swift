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
    
    var backgroundColor: Color {
        switch appState.detectionState {
        case .disabled:
            return Color(UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3))
        case .searching:
            return Color(UIColor(red: 1, green: 1, blue: 1, alpha: 0.3))
        case .tracking:
            return Color(UIColor(red: 0, green: 0.75, blue: 0, alpha: 0.3))
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
            .background(backgroundColor)
            .background(.clear)
        }
        .environmentObject(appState)
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
    @EnvironmentObject var appState: SwiftUIState
    
    class Coordinator: NSObject, ViewControllerDelegate {
        var parent: ViewControllerRepresentable
        
        init(_ parent: ViewControllerRepresentable) {
            self.parent = parent
        }
        
        func setAngle(_ angle: Double) {
            DispatchQueue.main.async {
                withAnimation {
                    self.parent.appState.angle = angle
                }
            }
        }
        
        func detectionState(didChange detectionState: SwiftUIState.DetectionState) {
            DispatchQueue.main.async {
                withAnimation {
                    self.parent.appState.detectionState = detectionState
                }
            }
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
            vc.delegate = context.coordinator
            return vc
        } else {
            return ViewController()
        }
    }
}

protocol ViewControllerDelegate {
    /// Set angle in radians
    func setAngle(_ angle: Double)
    /// Update tracking state
    func detectionState(didChange: SwiftUIState.DetectionState)
}

extension ViewControllerDelegate {
    func setAngle(_ angle: Double) {
        
    }
    
    func detectionState(didChange detectionState: SwiftUIState.DetectionState) {
        
    }
}
