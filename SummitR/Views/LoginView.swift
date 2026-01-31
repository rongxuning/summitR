//
//  LoginView.swift
//  SummitR
//
//  Created on 2026-01-31.
//

import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    @State private var account = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    
    var body: some View {
        ZStack {
            LoginBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 22) {
                Spacer(minLength: 40)
                
                VStack(spacing: 12) {
                    LogoHeader()
                    
                    Text("SummitR")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.7))
                }
                
                Spacer(minLength: 12)
                
                VStack(spacing: 14) {
                    RoundedInputField(
                        placeholder: "账号",
                        text: $account,
                        isSecure: false
                    )
                    
                    RoundedInputField(
                        placeholder: "密码",
                        text: $password,
                        isSecure: true
                    )
                }
                .padding(.horizontal, 34)
                
                VStack(spacing: 12) {
                    Button {
                        guard !isLoggingIn else { return }
                        isLoggingIn = true
                        // Demo 登录：直接进入首页
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isLoggedIn = true
                            isLoggingIn = false
                        }
                    } label: {
                        Text(isLoggingIn ? "登录中…" : "登录")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.02, green: 0.55, blue: 0.88),
                                        Color(red: 0.00, green: 0.75, blue: 0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                    }
                    .disabled(isLoggingIn)
                    
                    Button {
                        // 预留：注册/找回密码
                    } label: {
                        Text("注册 / 找回密码")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.95))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.white.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 23, style: .continuous)
                                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 34)
                
                Spacer(minLength: 40)
            }
        }
    }
}

private struct LogoHeader: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 118, height: 118)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
            
            // 如果你把图片放进 Assets.xcassets 的 Logo.imageset，这里就能直接显示
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 105, height: 105)
                .clipShape(Circle())
        }
    }
}

private struct RoundedInputField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .font(.system(size: 15, weight: .medium, design: .rounded))
        .padding(.horizontal, 18)
        .frame(height: 48)
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
    }
}

private struct LoginBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.35, blue: 0.78),
                    Color(red: 0.07, green: 0.70, blue: 0.92),
                    Color(red: 0.40, green: 0.90, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // 淡淡的几何纹理（参考图里的线框感）
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 36
                    for y in stride(from: -geo.size.height, to: geo.size.height * 2, by: step) {
                        path.move(to: CGPoint(x: -40, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width + 40, y: y + 120))
                    }
                }
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    LoginView()
}

