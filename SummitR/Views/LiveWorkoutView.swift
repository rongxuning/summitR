//
//  LiveWorkoutView.swift
//  SummitR
//

import SwiftUI
import HealthKit

private let zoneNames = ["Z1 恢复", "Z2 有氧", "Z3 节奏", "Z4 阈值", "Z5 摄氧", "Z6 无氧"]
private let zoneColors: [Color] = [.blue, .cyan, .green, .yellow, .orange, .red]

struct LiveWorkoutView: View {
    @ObservedObject var workoutManager: WorkoutManager
    let onDismiss: () -> Void
    
    @State private var showEndConfirm = false
    
    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.14, blue: 0.30)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部：训练类型 + 时间
                    HStack {
                        Text(workoutManager.activityTypeName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatElapsed(workoutManager.elapsedTime))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.35, green: 0.88, blue: 1.00))
                    }
                    .padding()
                    
                    // 主要指标卡片（心率可来自已配对 Apple Watch 等设备）
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metricCard(title: "心率", value: workoutManager.heartRate.map { "\(Int($0))" } ?? "—", unit: "bpm", subtitle: "来自手表等已配对设备")
                        metricCard(title: "平均心率", value: workoutManager.averageHeartRate.map { "\(Int($0))" } ?? "—", unit: "bpm")
                        metricCard(title: "动态消耗", value: String(format: "%.0f", workoutManager.activeEnergyBurned), unit: "千卡")
                        metricCard(title: "总消耗", value: String(format: "%.0f", workoutManager.totalEnergyBurned > 0 ? workoutManager.totalEnergyBurned : workoutManager.activeEnergyBurned), unit: "千卡")
                        metricCard(title: "距离", value: formatDistance(workoutManager.distance), unit: nil)
                        metricCard(title: "爬升", value: formatFlights(workoutManager.flightsClimbed), unit: nil)
                    }
                    .padding(.horizontal)
                    
                    // 心率曲线图（参考 WorkoutDetailView）
                    if let start = workoutManager.startDate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("心率曲线")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            LiveHeartRateChartView(
                                samples: workoutManager.heartRateSamples,
                                startDate: start,
                                endDate: Date(),
                                maxHR: workoutManager.workoutMaxHR,
                                restingHR: workoutManager.workoutRestingHR,
                                reserve: workoutManager.workoutReserve
                            )
                            .frame(height: 180)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                    
                    // 心率区间：时间 + 时间条（参考 WorkoutDetailView 六区）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("心率区间（六区）")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        VStack(spacing: 6) {
                            let totalDuration = workoutManager.timeInZones?.reduce(0, +) ?? 0
                            ForEach(0..<6, id: \.self) { idx in
                                let isCurrent = workoutManager.currentZoneIndex == idx
                                let bounds = workoutManager.zoneBounds(zoneIndex: idx)
                                let duration = workoutManager.timeInZones.flatMap { idx < $0.count ? $0[idx] : nil }
                                HStack(alignment: .center, spacing: 6) {
                                    Text(zoneNames[idx])
                                        .font(.caption)
                                        .fontWeight(isCurrent ? .bold : .medium)
                                        .foregroundColor(isCurrent ? .white : .white.opacity(0.8))
                                        .frame(width: 48, alignment: .leading)
                                    
                                    HStack(spacing: 4) {
                                        Text(formatDuration(duration ?? 0))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                            .frame(width: 36, alignment: .trailing)
                                        liveTimeBar(duration: duration ?? 0, total: totalDuration > 0 ? totalDuration : 1, zoneIndex: idx)
                                            .frame(minWidth: 40, maxWidth: .infinity)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    if let b = bounds {
                                        Text("\(b.low)–\(b.high)")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(width: 52, alignment: .trailing)
                                    }
                                    if isCurrent {
                                        Image(systemName: "location.fill")
                                            .font(.caption2)
                                            .foregroundColor(zoneColors[idx])
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isCurrent ? zoneColors[idx].opacity(0.35) : Color.white.opacity(0.08))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 24)
                    
                    // 结束按钮
                    Button(action: { showEndConfirm = true }) {
                        Text("结束锻炼")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("结束锻炼", isPresented: $showEndConfirm) {
            Button("取消", role: .cancel) {}
            Button("结束", role: .destructive) {
                workoutManager.endWorkout()
                onDismiss()
            }
        } message: {
            Text("确定要结束本次锻炼吗？")
        }
    }
    
    private func metricCard(title: String, value: String, unit: String?, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                if let u = unit, !u.isEmpty {
                    Text(u)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            if let sub = subtitle, !sub.isEmpty {
                Text(sub)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }
    
    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let t = Int(seconds)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters <= 0 { return "—" }
        if meters >= 1000 {
            return String(format: "%.2f 公里", meters / 1000)
        }
        return String(format: "%.0f 米", meters)
    }
    
    private func formatFlights(_ flights: Double) -> String {
        if flights <= 0 { return "—" }
        return String(format: "%.0f 层", flights)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        if m >= 60 {
            let h = m / 60
            let min = m % 60
            return String(format: "%d:%02d:%02d", h, min, s)
        }
        return String(format: "%d:%02d", m, s)
    }
    
    private func liveTimeBar(duration: TimeInterval, total: TimeInterval, zoneIndex: Int) -> some View {
        let ratio = total > 0 ? CGFloat(duration / total) : 0
        let color = zoneIndex < zoneColors.count ? zoneColors[zoneIndex] : Color.gray
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.15))
                    .frame(maxWidth: .infinity)
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(2, geo.size.width * ratio), height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - 实时心率曲线图（深色背景，白轴 + 六区着色折线）
struct LiveHeartRateChartView: View {
    let samples: [(Date, Double)]
    let startDate: Date
    let endDate: Date
    let maxHR: Double
    let restingHR: Double
    let reserve: Double
    
    private let leftMargin: CGFloat = 40
    private let rightMargin: CGFloat = 10
    private let topMargin: CGFloat = 10
    private let bottomMargin: CGFloat = 22
    
    private var yTicks: [Double] {
        (0...6).map { i in
            let pct = [0.50, 0.60, 0.70, 0.80, 0.90, 0.95, 1.00][i]
            return restingHR + reserve * pct
        }
    }
    
    private var yMin: Double {
        guard let sampleMin = samples.map(\.1).min() else { return yTicks.first ?? restingHR }
        return sampleMin - 2
    }
    private var yMax: Double { yTicks.last ?? maxHR }
    private var yRange: Double { max(yMax - yMin, 1) }
    
    private var duration: TimeInterval { endDate.timeIntervalSince(startDate) }
    private static let zoneColors: [Color] = [.blue, .cyan, .green, .yellow, .orange, .red]
    
    private func zoneIndex(hr: Double) -> Int {
        guard reserve > 0 else { return 0 }
        let pct = (hr - restingHR) / reserve
        if pct < 0.60 { return 0 }
        if pct < 0.70 { return 1 }
        if pct < 0.80 { return 2 }
        if pct < 0.90 { return 3 }
        if pct < 0.95 { return 4 }
        return 5
    }
    
    private func zoneColor(for hr: Double) -> Color {
        let idx = zoneIndex(hr: hr)
        return idx < Self.zoneColors.count ? Self.zoneColors[idx] : .red
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let plotW = w - leftMargin - rightMargin
            let plotH = h - topMargin - bottomMargin
            
            ZStack(alignment: .topLeading) {
                // 虚线网格（浅色）
                ForEach(Array(yTicks.dropFirst().dropLast().enumerated()), id: \.offset) { _, hr in
                    let y = topMargin + plotH * (1 - CGFloat((hr - yMin) / yRange))
                    Path { path in
                        path.move(to: CGPoint(x: leftMargin, y: y))
                        path.addLine(to: CGPoint(x: w - rightMargin, y: y))
                    }
                    .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                
                // 实线 X/Y 轴
                Path { path in
                    path.move(to: CGPoint(x: leftMargin, y: h - bottomMargin))
                    path.addLine(to: CGPoint(x: w - rightMargin, y: h - bottomMargin))
                }
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                Path { path in
                    path.move(to: CGPoint(x: leftMargin, y: topMargin))
                    path.addLine(to: CGPoint(x: leftMargin, y: h - bottomMargin))
                }
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                
                // 心率折线（六区着色）
                if samples.count >= 2, duration > 0 {
                    let sorted = samples.sorted { $0.0 < $1.0 }
                    ForEach(Array(0..<(sorted.count - 1)), id: \.self) { i in
                        let t0 = sorted[i].0.timeIntervalSince(startDate)
                        let t1 = sorted[i + 1].0.timeIntervalSince(startDate)
                        let x0 = leftMargin + CGFloat(t0 / duration) * plotW
                        let x1 = leftMargin + CGFloat(t1 / duration) * plotW
                        let y0 = topMargin + plotH * (1 - CGFloat((sorted[i].1 - yMin) / yRange))
                        let y1 = topMargin + plotH * (1 - CGFloat((sorted[i + 1].1 - yMin) / yRange))
                        Path { path in
                            path.move(to: CGPoint(x: x0, y: y0))
                            path.addLine(to: CGPoint(x: x1, y: y1))
                        }
                        .stroke(zoneColor(for: sorted[i].1), lineWidth: 2)
                    }
                }
                
                // Y 轴标签
                ForEach(Array([yMin] + yTicks.filter { $0 > yMin && $0 <= yMax }).sorted().enumerated(), id: \.offset) { _, hr in
                    let y = topMargin + plotH * (1 - CGFloat((hr - yMin) / yRange))
                    Text("\(Int(hr))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: leftMargin - 6, alignment: .trailing)
                        .position(x: (leftMargin - 6) / 2 + 4, y: y)
                }
                
                // X 轴标签：起始 + 每 5 分钟
                let step: TimeInterval = 5 * 60
                let tickCount = max(1, Int(duration / step) + 1)
                ForEach(0..<tickCount, id: \.self) { i in
                    let t = startDate.addingTimeInterval(TimeInterval(i) * step)
                    let tx = TimeInterval(i) * step
                    let x = leftMargin + CGFloat(tx / duration) * plotW
                    if t <= endDate && x <= w - rightMargin - 4 {
                        Text(Self.timeFormatter.string(from: t))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 32, alignment: .center)
                            .position(x: x, y: h - bottomMargin + 12)
                    }
                }
            }
        }
    }
}
