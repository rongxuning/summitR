//
//  GymBackgroundView.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI

struct GymBackgroundView: View {
    var body: some View {
        ZStack {
            // 背景渐变 - 模拟健身房地板和墙壁
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.2, blue: 0.25), // 深色墙壁
                    Color(red: 0.3, green: 0.3, blue: 0.35), // 中色
                    Color(red: 0.25, green: 0.25, blue: 0.3)  // 地板色
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // 像素风格的健身房元素
            VStack {
                // 天花板灯光
                HStack {
                    ForEach(0..<8) { _ in
                        Circle()
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // 地板瓷砖 - 像素风格
                HStack(spacing: 0) {
                    ForEach(0..<20) { _ in
                        Rectangle()
                            .fill(Color(red: 0.35, green: 0.35, blue: 0.4))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.25), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 20)
            }
            
            // 侧边设备（像素风格）
            HStack {
                // 左侧设备
                VStack {
                    Spacer()
                    PixelEquipmentView()
                        .padding(.leading, 20)
                }
                
                Spacer()
                
                // 右侧设备
                VStack {
                    Spacer()
                    PixelEquipmentView()
                        .padding(.trailing, 20)
                }
            }
        }
    }
}

struct PixelEquipmentView: View {
    var body: some View {
        VStack(spacing: 4) {
            // 杠铃架
            Rectangle()
                .fill(Color(red: 0.4, green: 0.4, blue: 0.45))
                .frame(width: 40, height: 60)
            
            // 哑铃
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(red: 0.5, green: 0.5, blue: 0.55))
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(Color(red: 0.5, green: 0.5, blue: 0.55))
                    .frame(width: 12, height: 12)
            }
        }
    }
}

#Preview {
    GymBackgroundView()
}
