//
//  WorkoutTypeSelectionView.swift
//  SummitR
//

import SwiftUI
import HealthKit

/// 可选运动类型（常用）
private let selectableActivityTypes: [HKWorkoutActivityType] = [
    .running,
    .walking,
    .cycling,
    .hiking,
    .swimming,
    .yoga,
    .highIntensityIntervalTraining,
    .functionalStrengthTraining,
    .elliptical,
    .rowing,
    .stairClimbing,
    .dance
]

struct WorkoutTypeSelectionView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @State private var isStarting = false
    @State private var showLiveWorkout = false
    @State private var selectedType: HKWorkoutActivityType?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView().ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(selectableActivityTypes, id: \.rawValue) { type in
                            Button(action: {
                                selectedType = type
                                startWorkout(type: type)
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: iconForActivity(type))
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(red: 0.35, green: 0.88, blue: 1.00))
                                    Text(type.displayNameZH)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .disabled(isStarting)
                        }
                    }
                    .padding()
                }
                .navigationTitle("选择运动类型")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { dismiss() }
                            .foregroundColor(.black)
                    }
                }
                .overlay {
                    if isStarting {
                        ProgressView("启动中...")
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                    }
                }
            }
            .fullScreenCover(isPresented: $showLiveWorkout) {
                if let type = selectedType {
                    LiveWorkoutView(
                        workoutManager: workoutManager,
                        onDismiss: {
                            showLiveWorkout = false
                            dismiss()
                        }
                    )
                }
            }
        }
        .task {
            await workoutManager.prepareForWorkout()
        }
    }
    
    private func startWorkout(type: HKWorkoutActivityType) {
        isStarting = true
        Task {
            await workoutManager.startWorkout(activityType: type)
            isStarting = false
            if workoutManager.isWorkoutActive {
                showLiveWorkout = true
            } else if let err = workoutManager.errorMessage {
                selectedType = nil
            }
        }
    }
    
    private func iconForActivity(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .hiking: return "figure.hiking"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.yoga"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell.fill"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .stairClimbing: return "figure.stairs"
        case .dance: return "figure.dance"
        default: return "figure.run"
        }
    }
}
