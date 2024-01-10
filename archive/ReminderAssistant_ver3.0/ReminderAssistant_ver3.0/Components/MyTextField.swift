//
//  MyTextField.swift
//  ReminderAssistant_ver3.0
//
//  Created by Masaki Doi on 2023/02/23.
//

import SwiftUI

struct MyTextField: View {
    
    let labelName: String
    let width: CGFloat
    var axix = Axis.horizontal
    var lineLimit = 1
    
    @Binding var text: String
    
    var coreColor: Color
    var bgColor: Color
    
    var focus: FocusState<Focus?>.Binding
    var focusStateValue: Focus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(labelName)
                .frame(width: width, alignment: .leading)
                .background(bgColor)
                .fontWeight(.semibold)
                .foregroundColor(coreColor)
                .padding(.leading, 1)
                .padding(.bottom, 4)
                .onTapGesture {
                    if focus.wrappedValue != focusStateValue { focus.wrappedValue = focusStateValue }
                }

            TextField("", text: $text, axis: axix)
                .lineLimit(lineLimit)
                .frame(width: width)
                .padding(.leading, 2)
                .focused(focus, equals: focusStateValue)

            RoundedRectangle(cornerRadius: 1)
                .foregroundColor(coreColor)
                .frame(width: width, height: 1)
                .padding(.top, 3)
                .onTapGesture {
                    if focus.wrappedValue != focusStateValue { focus.wrappedValue = focusStateValue }
                }
        }
    }
}





struct MyTextField_Previews: PreviewProvider {
    @FocusState static var focus: Focus?
    static var previews: some View {
//        MyTextField(labelName: "Name", width: 320, title: Binding.constant(""), coreColor: .blue, bgColor: .white, focus: $focus)
        MyTextField(labelName: "Name", width: 320, text: Binding.constant(""), coreColor: .blue, bgColor: .white, focus: $focus, focusStateValue: .title)
        
    }
}
