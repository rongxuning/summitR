//
//  PersonView.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI
import Foundation

// MARK: - Math helpers (avoid CGFloat/Double ambiguity in Xcode)
private func sinWave(_ phase: CGFloat) -> CGFloat {
    // phase: 0...1
    CGFloat(sin(Double(phase) * 2.0 * Double.pi))
}

private func sinWaveDouble(_ phase: CGFloat) -> Double {
    sin(Double(phase) * 2.0 * Double.pi)
}

struct PersonView: View {
    let exercise: ExerciseType
    let gender: Gender
    let delay: Double
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            switch exercise {
            case .squat:
                SquatPersonView(gender: gender, phase: animationPhase)
            case .deadlift:
                DeadliftPersonView(gender: gender, phase: animationPhase)
            case .plank:
                PlankPersonView(gender: gender, phase: animationPhase)
            case .pushup:
                PushupPersonView(gender: gender, phase: animationPhase)
            case .pullup:
                PullupPersonView(gender: gender, phase: animationPhase)
            case .rowing:
                RowingPersonView(gender: gender, phase: animationPhase)
            case .bike:
                BikePersonView(gender: gender, phase: animationPhase)
            }
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
            ) {
                animationPhase = 1.0
            }
        }
    }
}

// MARK: - 像素风格基础人物组件

struct PixelHead: View {
    let gender: Gender
    
    var body: some View {
        ZStack {
            // 头部
            Rectangle()
                .fill(gender == .male ? Color(red: 0.9, green: 0.7, blue: 0.5) : Color(red: 1.0, green: 0.8, blue: 0.6))
                .frame(width: 16, height: 16)
            
            // 头发
            if gender == .female {
                VStack {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 4, height: 4)
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 8, height: 4)
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 4, height: 4)
                    }
                    Spacer()
                }
            }
            
            // 眼睛
            HStack(spacing: 4) {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 2)
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 2)
            }
            .offset(y: 2)
        }
    }
}

struct PixelBody: View {
    let gender: Gender
    let color: Color
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 20, height: 24)
    }
}

struct PixelArm: View {
    let color: Color
    let rotation: Double
    let offset: CGSize
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 6, height: 16)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
    }
}

struct PixelLeg: View {
    let color: Color
    let rotation: Double
    let offset: CGSize
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 6, height: 20)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
    }
}

// MARK: - 各种运动的人物视图

struct SquatPersonView: View {
    let gender: Gender
    let phase: CGFloat
    
    var bodyColor: Color {
        gender == .male ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.8, green: 0.3, blue: 0.5)
    }
    
    var body: some View {
        ZStack {
            // 杠铃
            Rectangle()
                .fill(Color(red: 0.6, green: 0.6, blue: 0.6))
                .frame(width: 40, height: 4)
                .offset(y: -20)
            
            // 身体
            PixelBody(gender: gender, color: bodyColor)
                .offset(y: sinWave(phase) * 8)
            
            // 头部
            PixelHead(gender: gender)
                .offset(y: -20 + sinWave(phase) * 8)
            
            // 手臂 - 举着杠铃
            PixelArm(color: bodyColor, rotation: 45, offset: CGSize(width: -12, height: -10))
            PixelArm(color: bodyColor, rotation: -45, offset: CGSize(width: 12, height: -10))
            
            // 腿部 - 深蹲动作
            let legRotation = sinWaveDouble(phase) * 30.0 + 15.0
            PixelLeg(color: bodyColor, rotation: legRotation, offset: CGSize(width: -6, height: 20))
            PixelLeg(color: bodyColor, rotation: -legRotation, offset: CGSize(width: 6, height: 20))
        }
    }
}

struct DeadliftPersonView: View {
    let gender: Gender
    let phase: CGFloat
    
    var bodyColor: Color {
        gender == .male ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.8, green: 0.3, blue: 0.5)
    }
    
    var body: some View {
        ZStack {
            // 杠铃在地面
            Rectangle()
                .fill(Color(red: 0.6, green: 0.6, blue: 0.6))
                .frame(width: 40, height: 4)
                .offset(y: 30)
            
            // 身体 - 弯腰动作
            PixelBody(gender: gender, color: bodyColor)
                .rotationEffect(.degrees(sinWaveDouble(phase) * 20.0 + 30.0))
                .offset(y: 10)
            
            // 头部
            PixelHead(gender: gender)
                .rotationEffect(.degrees(sinWaveDouble(phase) * 20.0 + 30.0))
                .offset(x: 0, y: -5)
            
            // 手臂 - 抓杠铃
            PixelArm(color: bodyColor, rotation: 60, offset: CGSize(width: -10, height: 15))
            PixelArm(color: bodyColor, rotation: -60, offset: CGSize(width: 10, height: 15))
            
            // 腿部
            PixelLeg(color: bodyColor, rotation: 10, offset: CGSize(width: -6, height: 25))
            PixelLeg(color: bodyColor, rotation: -10, offset: CGSize(width: 6, height: 25))
        }
    }
}

struct PlankPersonView: View {
    let gender: Gender
    let phase: CGFloat
    
    var bodyColor: Color {
        gender == .male ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.8, green: 0.3, blue: 0.5)
    }
    
    var body: some View {
        ZStack {
            // 身体 - 水平
            PixelBody(gender: gender, color: bodyColor)
                .rotationEffect(.degrees(90))
                .frame(width: 24, height: 20)
                .offset(y: sinWave(phase) * 2)
            
            // 头部
            PixelHead(gender: gender)
                .rotationEffect(.degrees(90))
                .offset(x: -12, y: 0)
            
            // 手臂 - 支撑
            PixelArm(color: bodyColor, rotation: 90, offset: CGSize(width: -15, height: 0))
            PixelArm(color: bodyColor, rotation: 90, offset: CGSize(width: 15, height: 0))
            
            // 腿部
            PixelLeg(color: bodyColor, rotation: 90, offset: CGSize(width: -8, height: 15))
            PixelLeg(color: bodyColor, rotation: 90, offset: CGSize(width: 8, height: 15))
        }
    }
}

struct PushupPersonView: View {
    let gender: Gender
    let phase: CGFloat
    
    var bodyColor: Color {
        gender == .male ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.8, green: 0.3, blue: 0.5)
    }
    
    var body: some View {
        ZStack {
            let verticalOffset = sinWave(phase) * 8
            
            // 身体
            PixelBody(gender: gender, color: bodyColor)
                .rotationEffect(.degrees(90))
                .frame(width: 24, height: 20)
                .offset(y: verticalOffset)
            
            // 头部
            PixelHead(gender: gender)
                .rotationEffect(.degrees(90))
                .offset(x: -12, y: verticalOffset)
            
            // 手臂 - 俯卧撑动作
            let armRotation = sinWaveDouble(phase) * 30.0 + 90.0
            PixelArm(color: bodyColor, rotation: armRotation, offset: CGSize(width: -15, height: verticalOffset))
            PixelArm(color: bodyColor, rotation: armRotation, offset: CGSize(width: 15, height: verticalOffset))
            
            // 腿部
            PixelLeg(color: bodyColor, rotation: 90, offset: CGSize(width: -8, height: 15 + verticalOffset))
            PixelLeg(color: bodyColor, rotation: 90, offset: CGSize(width: 8, height: 15 + verticalOffset))
        }
    }
}

struct PullupPersonView: View {
    let gender: Gender
    let phase: CGFloat
    
    var bodyColor: Color {
        gender == .male ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.8, green: 0.3, blue: 0.5)
    }
    
    var body: some View {
        ZStack {
            // 单杠
            Rectangle()
                .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                .frame(width: 50, height: 4)
                .offset(y: -30)
            
            let verticalOffset = sinWave(phase) * 10
            
            // 身体
            PixelBody(gender: gender, color: bodyColor)
                .offset(y: -10 + verticalOffset)
            
            // 头部
            PixelHead(gender: gender)
                .offset(y: -20 + verticalOffset)
            
            // 手臂 - 抓单杠
            PixelArm(color: bodyColor, rotation: 135, offset: CGSize(width: -12, height: -15 + verticalOffset))
            PixelArm(color: bodyColor, rotation: -135, offset: CGSize(width: 12, height: -15 + verticalOffset))
            
            // 腿部
            PixelLeg(color: bodyColor, rotation: 0, offset: CGSize(width: -6, height: 10 + verticalOffset))
            PixelLeg(color: bodyColor, rotation: 0, offset: CGSize(width: 6, height: 10 + verticalOffset))
        }
    }
}

struct RowingPersonView: View {
    let gender: Gender
    let phase: CGFloat
    
    var bodyColor: Color {
        gender == .male ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.8, green: 0.3, blue: 0.5)
    }
    
    var body: some View {
        ZStack {
            // 划船机
            Rectangle()
                .fill(Color(red: 0.4, green: 0.4, blue: 0.4))
                .frame(width: 50, height: 8)
                .offset(y: 20)
            
            let armOffset = sinWave(phase) * 15
            let armRotationDelta = Double(armOffset)
            
            // 身体
            PixelBody(gender: gender, color: bodyColor)
                .offset(x: armOffset * 0.3)
            
            // 头部
            PixelHead(gender: gender)
                .offset(x: armOffset * 0.3, y: -20)
            
            // 手臂 - 划船动作
            PixelArm(color: bodyColor, rotation: 45 + armRotationDelta, offset: CGSize(width: -12 + armOffset, height: -5))
            PixelArm(color: bodyColor, rotation: -45 - armRotationDelta, offset: CGSize(width: 12 + armOffset, height: -5))
            
            // 腿部
            PixelLeg(color: bodyColor, rotation: 10, offset: CGSize(width: -6, height: 20))
            PixelLeg(color: bodyColor, rotation: -10, offset: CGSize(width: 6, height: 20))
        }
    }
}

struct BikePersonView: View {
    let gender: Gender
    let phase: CGFloat
    
    var bodyColor: Color {
        gender == .male ? Color(red: 0.2, green: 0.4, blue: 0.8) : Color(red: 0.8, green: 0.3, blue: 0.5)
    }
    
    var body: some View {
        ZStack {
            // 单车
            Circle()
                .stroke(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 3)
                .frame(width: 30, height: 30)
                .offset(y: 15)
            
            let legRotation = Double(phase) * 360.0
            
            // 身体
            PixelBody(gender: gender, color: bodyColor)
                .offset(y: -5)
            
            // 头部
            PixelHead(gender: gender)
                .offset(y: -20)
            
            // 手臂 - 扶把手
            PixelArm(color: bodyColor, rotation: 30, offset: CGSize(width: -10, height: -8))
            PixelArm(color: bodyColor, rotation: -30, offset: CGSize(width: 10, height: -8))
            
            // 腿部 - 蹬车动作
            PixelLeg(color: bodyColor, rotation: legRotation, offset: CGSize(width: -6, height: 10))
            PixelLeg(color: bodyColor, rotation: legRotation + 180.0, offset: CGSize(width: 6, height: 10))
        }
    }
}

#Preview {
    VStack {
        SquatPersonView(gender: .male, phase: 0.5)
        DeadliftPersonView(gender: .female, phase: 0.5)
    }
}
