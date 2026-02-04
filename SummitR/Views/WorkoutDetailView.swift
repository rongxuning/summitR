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
    @State private var isLoadingDetail = true
    
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
                    // 名称
                    detailSection(title: "名称", systemImage: "tag.fill") {
                        Text(record.activityTypeName)
                            .font(.headline)
                    }
                    
                    // 时间
                    detailSection(title: "时间", systemImage: "calendar") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.dateFormatted)
                            Text(record.timeRangeFormatted)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 类型
                    detailSection(title: "类型", systemImage: "figure.run") {
                        Text(record.activityTypeName)
                    }
                    
                    // 耗能等级
                    detailSection(title: "耗能等级", systemImage: "flame.fill") {
                        Text(energyLevel)
                            .foregroundColor(energyLevelColor)
                    }
                    
                    // 训练时间
                    detailSection(title: "训练时间", systemImage: "timer") {
                        Text(record.durationFormatted)
                    }
                    
                    // 动态签卡（活动状态）
                    detailSection(title: "活动状态", systemImage: "checkmark.circle.fill") {
                        Text("已记录")
                            .foregroundColor(.secondary)
                    }
                    
                    // 总千卡
                    detailSection(title: "总千卡", systemImage: "flame.fill") {
                        Text(record.energyFormatted ?? "—")
                    }
                    
                    // 平均心率
                    detailSection(title: "平均心率", systemImage: "heart.fill") {
                        if let avg = averageHeartRate {
                            Text(String(format: "%.0f bpm", avg))
                                .foregroundColor(.red)
                        } else {
                            Text("—")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 心率/时间曲线
                    if !heartRateSamples.isEmpty {
                        detailSection(title: "心率曲线", systemImage: "waveform.path.ecg") {
                            HeartRateChartView(samples: heartRateSamples)
                                .frame(height: 160)
                        }
                    }
                    
                    // 地点 / 地图
                    if !routeLocations.isEmpty {
                        detailSection(title: "路线", systemImage: "map.fill") {
                            WorkoutRouteMapView(locations: routeLocations)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        detailSection(title: "地点", systemImage: "location") {
                            Text("未记录路线")
                                .foregroundColor(.secondary)
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
    
    private var energyLevelColor: Color {
        switch energyLevel {
        case "高": return .orange
        case "中": return .green
        case "低": return .blue
        default: return .secondary
        }
    }
    
    private func detailSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func loadDetail() async {
        isLoadingDetail = true
        defer { isLoadingDetail = false }
        
        let hrSamples = await healthKitManager.fetchHeartRateSamples(from: record.startDate, to: record.endDate)
        heartRateSamples = hrSamples
        
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
