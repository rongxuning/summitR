//
//  HomeCoverView.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI

struct HomeCoverView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 背景与登录页一致
            AppBackgroundView()
                .ignoresSafeArea()
            
            // 轻微暗层，提升前景对比度
            Color.black.opacity(0.08)
            
            // 动态人物
            VStack {
                Spacer()
                
                HStack(spacing: 20) {
                    // 第一排人物
                    PersonView(exercise: .squat, gender: .male, delay: 0)
                    PersonView(exercise: .deadlift, gender: .female, delay: 0.2)
                    PersonView(exercise: .plank, gender: .male, delay: 0.4)
                    PersonView(exercise: .pushup, gender: .female, delay: 0.6)
                }
                
                HStack(spacing: 20) {
                    // 第二排人物
                    PersonView(exercise: .pullup, gender: .male, delay: 0.1)
                    PersonView(exercise: .rowing, gender: .female, delay: 0.3)
                    PersonView(exercise: .bike, gender: .male, delay: 0.5)
                    PersonView(exercise: .squat, gender: .female, delay: 0.7)
                }
                
                Spacer()
            }
            .padding()
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            // 为底部导航栏留出空间
            Color.clear.frame(height: 64)
        }
    }
}

#Preview {
    HomeCoverView()
}
