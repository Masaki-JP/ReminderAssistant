//
//  SampleUI.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/11/23.
//

import SwiftUI

struct SampleUI: View {

    @State var text1 = ""
    @State var text2 = ""
    @State var text3 = ""
    @FocusState var focusState: FocusField?
    enum FocusField {
        case one
        case two
        case three
    }

    var body: some View {
        ZStack {

            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()

            VStack {

                if focusState == nil {
                    Text("Let's create reminders")
                        .bold().foregroundColor(.white).font(.largeTitle)
                        .frame(width: UIScreen.main.bounds.width)
                        .padding(.vertical)
                        .background(Color(red: 0.075, green: 0.075, blue: 0.075))
                    Spacer()
                }


                Group {

                    HStack {
                        TextField("Reminder title", text: $text1)
                            .focused($focusState, equals: .one)
                        if text1 != "" {
                            Image(systemName: "clear").foregroundColor(.gray)
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width*0.8)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)

                    HStack {
                        TextField("Deadline", text: $text2)
                            .focused($focusState, equals: .two)
                        if text2 != "" {
                            Image(systemName: "clear").foregroundColor(.gray)
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width*0.8)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .padding(.top, 20)


                    HStack {
                        TextField("Notes (option)", text: $text3, axis: .vertical)
                            .lineLimit(4)
                            .focused($focusState, equals: .three)
                            .toolbar {
                                ToolbarItem(placement: .keyboard) {
                                    Button {
                                        var store = text3
                                        text3 = ""
                                        focusState = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.03) {
                                            text3 = store
                                            store = ""
                                        }
                                    } label: {
                                        Text("完了")
                                    }
                                }
                            }
                    }
                    .frame(width: UIScreen.main.bounds.width*0.8)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .padding(.top, 20)
                }


                Button {
                } label: {
                    Text("Create a reminder")
                        .bold().font(.title).foregroundColor(.white).padding()
                        .background(Color(red: 230/270, green: 121/270, blue: 40/270))
                        .cornerRadius(100)
                        .padding(.top, 25)
                }

                Text("作成先リスト：マイタスク")
                    .font(.callout).padding(.top, 5)

                if focusState == nil {
                    Spacer()
                }
            }
        }
    }
}

struct SampleUI_Previews: PreviewProvider {
    static var previews: some View {
        SampleUI()
    }
}
