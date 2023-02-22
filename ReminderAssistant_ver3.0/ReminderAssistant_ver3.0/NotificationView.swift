//
//  NotificationView.swift
//  ReminderAssistant_ver3.0
//
//  Created by Masaki Doi on 2023/02/21.
//

import SwiftUI

struct NotificationView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var showSuccessView: Bool
    @Binding var title: String
    @Binding var deadline: String

    var body: some View {
        ZStack {
            
            //Alert
            Group {
                // BGColor_Alert
                if showSuccessView {
                    ZStack {
                        Color.gray.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    showSuccessView = false
                                }
                            }
                    }
                    .transition(.opacity)
                }
                
                // Alert
                if showSuccessView {
                    VStack {
                        VStack {
                            Text("Success!!")
                                .font(.custom("Rockwell-Regular", size: 25))
                                .baselineOffset(UIFont(name: "Rockwell-Regular", size: 25)!.descender)
                                .foregroundColor(.primary)
                                .padding(.top)
                            
                            Text(title)
                                .font(.footnote)
                                .foregroundColor(colorScheme == .light ? .secondary : .white)
                                .padding(.top, 3)
                            
                            Text("(\(deadline))")
                                .font(.footnote)
                                .foregroundColor(colorScheme == .light ? .secondary : .white)
                                .padding(.bottom, 3)
                        }
                        .padding()
                        .padding(.top)
                    }
                    .frame(width: 250)
                    .background(colorScheme == .light ? .white : .black)
                    .cornerRadius(20)
                    .overlay(alignment: .top) {
                        Circle()
                            .foregroundColor(.blue)
                            .frame(width: 60, height: 60)
                            .overlay(content: {
                                
                                
                                Image(systemName: "hand.thumbsup.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .padding()
                                
                                Circle()
                                    .stroke(colorScheme == .light ? .white : .black, lineWidth: 5)
                            })
                            .padding(.top, -30)
                    }
                    .frame(maxHeight: .infinity)
                    .shadow(radius: 3)
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView(showSuccessView: Binding.constant(true), title: Binding.constant("買い物に行く"), deadline: Binding.constant("2023年2月20日 15:00"))
    }
}
