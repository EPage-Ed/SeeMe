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
    
    var body: some View {
        ZStack {
            ViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .foregroundColor(.clear)
                        Image(systemName: "face.dashed")
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

    }
}


struct NavigationScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationScreen()
    }
}

struct ViewControllerRepresentable: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        
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
