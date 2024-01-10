//
//  MyButton.swift
//  ReminderAssistant_ver3.0
//
//  Created by Masaki Doi on 2023/02/23.
//

import SwiftUI

struct MyButton: View {
    
    var text: String
    
    var color: Color
    
    var width: CGFloat
    
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .frame(width: width)
                .background(color)
                .cornerRadius(5)
        }
        .keyboardShortcut(.return, modifiers: .command)
    }
}

struct MyButton_Previews: PreviewProvider {
    static var previews: some View {
        MyButton(text: "print", color: .pink, width: 320) {
            print("pushed")
        }
    }
}
