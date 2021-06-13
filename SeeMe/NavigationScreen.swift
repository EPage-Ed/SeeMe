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
}

struct NavigationScreen: View {
    @StateObject var appState = SwiftUIState()
    
    var body: some View {
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
                        .onAppear {
                            withAnimation {
                                appState.angle = .pi*6
                            }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color(UIColor(red: 0, green: 0.75, blue: 0, alpha: 0.5)))
        .background(.ultraThinMaterial)

    }
}

struct NavigationScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationScreen()
    }
}
