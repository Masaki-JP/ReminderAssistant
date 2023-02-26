//
//  NotificationView.swift
//  ReminderAssistant_ver3.0
//
//  Created by Masaki Doi on 2023/02/21.
//

import SwiftUI

struct NotificationView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var showView: Bool
    @Binding var title: String
    @Binding var deadline: String
    
    var bgColor1: Color {
        if colorScheme == .light {
            return .white
        } else {
            return Color(red: 0.125, green: 0.125, blue: 0.15)
        }
    }
    
    var bgColor2: Color {
        if colorScheme == .light {
            return Color.gray.opacity(0.3)
        } else {
            return Color.black.opacity(0.6)
        }
    }
    
    var body: some View {
        ZStack {
            
            // Background
            if showView {
                ZStack {
//                    bgColor2
//                        .ignoresSafeArea()
//                        .onTapGesture {
//                            withAnimation {
//                                showView = false
//                            }
//                        }
                    Button {
                        withAnimation {
                            showView = false
                        }
                    } label: {
                            bgColor2
                                .ignoresSafeArea()
                    }
                    .keyboardShortcut(.defaultAction)

                }
                .transition(.opacity)
            }
            
            // View
            if showView {
                VStack {
                    VStack {
                        VStack {
                            
                            // コンテンツ開始
                            
                            
                            Text("Success!!")
                                .font(.custom("Rockwell-Regular", size: 25))
                                .baselineOffset(UIFont(name: "Rockwell-Regular", size: 25)!.descender)
                                .foregroundColor(.primary)
                            
                            Text(title)
                                .font(.footnote)
                                .foregroundColor(colorScheme == .light ? .secondary : .white)
                                .padding(.top, 3)
                            
                            Text("(\(deadline))")
                                .font(.footnote)
                                .foregroundColor(colorScheme == .light ? .secondary : .white)
                                .padding(.bottom, 3)
                            
                            // コンテンツ終了
                        }
                        .padding(.top, 35)
                        .padding(.bottom)
                        
                    }
                    .padding(.horizontal)
                    .frame(width: 250, height: 140)
                    .background(bgColor1)
                    .cornerRadius(20)
                    .overlay(alignment: .top) {
                        Circle()
                            .foregroundColor(Color(red: 64/255, green: 123/255, blue: 255/255))
                            .frame(width: 60, height: 60)
                            .overlay(content: {
                                Image(systemName: "hand.thumbsup.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .padding()
                                
                                Circle()
                                    .stroke(bgColor1, lineWidth: 5)
                                    .frame(width: 60, height: 60)
                            })
                            .padding(.top, -30)
                    }
                    .shadow(color: .clear, radius: 0)
                }
                .shadow(color: colorScheme == .light ? .gray : .clear, radius: 3)
                .frame(maxHeight: .infinity)
                .transition(.move(edge: .bottom))
            }
            
        }
    }
}

struct OldNotificationView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var showView: Bool
    @Binding var title: String
    @Binding var deadline: String

    var body: some View {
        ZStack {
            
            //Alert
            Group {
                // BGColor_Alert
                if showView {
                    ZStack {
                        Color.gray.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    showView = false
                                }
                            }
                    }
                    .transition(.opacity)
                }
                
                // Alert
                if showView {
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
        NotificationView(showView: Binding.constant(true), title: Binding.constant("買い物に行く"), deadline: Binding.constant("2023年2月20日 15:00"))
    }
}
