//
//  WorkoutDetailView.swift
//  SummitR
//

import SwiftUI
import HealthKit
import MapKit
import CoreLocation

struct WorkoutDetailView: View {
    let record: WorkoutRecordItem
    @ObservedObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var heartRateSamples: [(Date, Double)] = []
    @State private var routeLocations: [CLLocation] = []
    @State private var restingHeartRate: Double?
    @State private var userAge: Int?
    @State private var isLoadingDetail = true
    
    /// 最大心率（公式：206.9 - 0.67×年龄），年龄从健康 App 获取，取不到用 34
    private var maxHeartRate: Double {
        206.9 - (0.67 * Double(userAge ?? 34))
    }
    
    /// 储备心率 = 最大心率 - 静息心率（静息无数据时用 60）
    private var heartRateReserve: Double {
        let resting = restingHeartRate ?? 60
        return Swift.max(0, maxHeartRate - resting)
    }
    
    private var averageHeartRate: Double? {
        guard !heartRateSamples.isEmpty else { return nil }
        let sum = heartRateSamples.reduce(0.0) { $0 + $1.1 }
        return sum / Double(heartRateSamples.count)
    }
    
    /// 耗能等级：根据总千卡与时长粗略划分
    private var energyLevel: String {
        guard let kcal = record.totalEnergyBurned, kcal > 0, record.duration > 0 else { return "—" }
        let kcalPerMin = kcal / (record.duration / 60.0)
        if kcalPerMin < 5 { return "低" }
        if kcalPerMin < 10 { return "中" }
        return "高"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoadingDetail {
                    ProgressView("加载详情…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    // 聚合：名称、时间、类型
                    detailSection(title: "基本信息", systemImage: "info.circle.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow(label: "名称", value: record.activityTypeName)
                            detailRow(label: "时间", value: record.dateFormatted + " " + record.timeRangeFormatted)
                            detailRow(label: "类型", value: record.activityTypeName)
                        }
                    }
                    
                    // 单独：心率曲线 + 最大/储备/六区
                    if !heartRateSamples.isEmpty {
                        detailSection(title: "心率曲线", systemImage: "waveform.path.ecg") {
                            VStack(alignment: .leading, spacing: 16) {
                                HeartRateChartView(samples: heartRateSamples)
                                    .frame(height: 160)
                                HeartRateStatsView(
                                    maxHR: maxHeartRate,
                                    reserve: heartRateReserve,
                                    restingHR: restingHeartRate ?? 60
                                )
                            }
                        }
                    }
                    
                    // 单独：地点 / 路线
                    if !routeLocations.isEmpty {
                        detailSection(title: "路线", systemImage: "map.fill") {
                            WorkoutRouteMapView(locations: routeLocations)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        detailSection(title: "地点", systemImage: "location") {
                            Text("未记录路线")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                    }
                    
                    // 聚合：能耗等级、训练时间、总千卡、动态千卡、平均心率
                    detailSection(title: "运动数据", systemImage: "chart.bar.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow(label: "耗能等级", value: energyLevel)
                            detailRow(label: "训练时间", value: record.durationFormatted)
                            detailRow(label: "总千卡", value: record.energyFormatted ?? "—")
                            detailRow(label: "动态千卡", value: "—")
                            if let avg = averageHeartRate {
                                detailRow(label: "平均心率", value: String(format: "%.0f bpm", avg))
                            } else {
                                detailRow(label: "平均心率", value: "—")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppBackgroundView().ignoresSafeArea())
        .navigationTitle("锻炼详情")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetail()
        }
    }
    
    private func detailSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.black)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.black)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
    }
    
    private func loadDetail() async {
        isLoadingDetail = true
        defer { isLoadingDetail = false }
        
        let hrSamples = await healthKitManager.fetchHeartRateSamples(from: record.startDate, to: record.endDate)
        heartRateSamples = hrSamples
        restingHeartRate = await healthKitManager.fetchRestingHeartRateValue()
        userAge = await healthKitManager.fetchUserAge()
        
        if let workout = await healthKitManager.fetchWorkout(byUUID: record.id) {
            let locs = await healthKitManager.fetchWorkoutRouteLocations(workout: workout)
            routeLocations = locs
        }
    }
}

// MARK: - 心率曲线（简单折线）
struct HeartRateChartView: View {
    let samples: [(Date, Double)]
    
    private var minHR: Double { (samples.map(\.1).min() ?? 0) - 10 }
    private var maxHR: Double { (samples.map(\.1).max() ?? 100) + 10 }
    private var range: Double { max(maxHR - minHR, 1) }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = max(samples.count, 1)
            let stepX = count > 1 ? w / CGFloat(count - 1) : w
            
            Path { path in
                for (i, sample) in samples.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = h - CGFloat((sample.1 - minHR) / range) * h
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.red, lineWidth: 2)
        }
    }
}

// MARK: - 心率曲线下方数据：最大心率、储备心率、六区模型
struct HeartRateStatsView: View {
    let maxHR: Double?
    let reserve: Double?
    let restingHR: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let max = maxHR {
                HStack {
                    Text("最大心率")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Spacer()
                    Text(String(format: "%.0f bpm", max))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }
            }
            if let r = reserve {
                HStack {
                    Text("储备心率")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Spacer()
                    Text(String(format: "%.0f bpm（静息 %.0f）", r, restingHR))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }
            }
            if reserve != nil {
                Text("六区模型（Karvonen）")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(zoneRangesForStats.enumerated()), id: \.offset) { _, zone in
                        zoneRow(name: zone.name, low: zoneLow(zone.low), high: zoneHigh(zone.high))
                    }
                }
            }
        }
    }
    
    private func zoneLow(_ pct: Double) -> Int {
        guard let r = reserve else { return 0 }
        return Int(restingHR + r * pct)
    }
    
    private func zoneHigh(_ pct: Double) -> Int {
        guard let r = reserve else { return 0 }
        return Int(restingHR + r * pct)
    }
    
    private func zoneRow(name: String, low: Int, high: Int) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.black)
            Spacer()
            Text("\(low)–\(high) bpm")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
    }
}

// 六区模型百分比（与 WorkoutDetailView.zoneRanges 一致，供 HeartRateStatsView 使用）
private let zoneRangesForStats: [(name: String, low: Double, high: Double)] = [
    ("Z1 恢复", 0.50, 0.60),
    ("Z2 有氧", 0.60, 0.70),
    ("Z3 节奏", 0.70, 0.80),
    ("Z4 阈值", 0.80, 0.90),
    ("Z5 VO2max", 0.90, 0.95),
    ("Z6 无氧", 0.95, 1.00)
]

// MARK: - 路线地图（带折线）
struct WorkoutRouteMapView: View {
    let locations: [CLLocation]
    
    private var coordinates: [CLLocationCoordinate2D] {
        locations.map { $0.coordinate }
    }
    
    var body: some View {
        WorkoutMapRepresentable(coordinates: coordinates)
    }
}

struct WorkoutMapRepresentable: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        if !coordinates.isEmpty {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            mapView.setRegion(region, animated: false)
        }
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    private var region: MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(
            record: WorkoutRecordItem(
                id: UUID(),
                activityType: .running,
                activityTypeName: "跑步",
                startDate: Date(),
                endDate: Date().addingTimeInterval(1800),
                duration: 1800,
                totalEnergyBurned: 280,
                totalDistance: 5000,
                sourceName: "健身"
            ),
            healthKitManager: HealthKitManager()
        )
    }
}
