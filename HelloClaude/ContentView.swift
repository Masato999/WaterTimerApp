//
//  ContentView.swift
//  HelloClaude
//
//  Created by 高橋正人 on 2026/08/12.
//

import SwiftUI
import Combine

private extension Color {
    static let appBackgroundTop = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let appBackgroundBottom = Color(red: 0.02, green: 0.02, blue: 0.03)
    static let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.13)
    static let accent = Color(red: 1.0, green: 0.48, blue: 0.27) // スタイリッシュなオレンジ系アクセント
}

private let presetIntervals = [5, 10, 15, 30, 45, 60]

struct ContentView: View {
    @StateObject private var settings = TimerSettingsStore()
    @State private var now = Date()

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 20) {
                    header
                    timeRangeCard
                    intervalCard
                    powerCard
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            NotificationManager.shared.apply(settings)
        }
        .onChange(of: settings.isEnabled) { _, _ in reschedule() }
        .onChange(of: settings.startHour) { _, _ in reschedule() }
        .onChange(of: settings.startMinute) { _, _ in reschedule() }
        .onChange(of: settings.endHour) { _, _ in reschedule() }
        .onChange(of: settings.endMinute) { _, _ in reschedule() }
        .onChange(of: settings.intervalMinutes) { _, _ in reschedule() }
        .onReceive(clock) { now = $0 }
    }

    private func reschedule() {
        NotificationManager.shared.apply(settings)
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: [.appBackgroundTop, .appBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("INTERVAL")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("トレーニング & 食事管理タイマー")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    // MARK: - Time range card

    private var timeRangeCard: some View {
        CardContainer(title: "有効時間帯", systemImage: "clock") {
            VStack(spacing: 14) {
                HStack {
                    labeledTimePicker(title: "開始", selection: $settings.startDate)
                    Spacer(minLength: 16)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer(minLength: 16)
                    labeledTimePicker(title: "終了", selection: $settings.endDate)
                }

                if settings.crossesMidnight {
                    Label("日をまたぐ設定です", systemImage: "moon.stars")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func labeledTimePicker(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(.accent)
                .colorScheme(.dark)
        }
    }

    // MARK: - Interval card

    private var intervalCard: some View {
        CardContainer(title: "通知間隔", systemImage: "timer") {
            VStack(spacing: 18) {
                HStack(spacing: 20) {
                    stepButton(systemImage: "minus") {
                        settings.intervalMinutes = max(1, settings.intervalMinutes - 5)
                    }

                    VStack(spacing: 0) {
                        Text("\(settings.intervalMinutes)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: settings.intervalMinutes)
                        Text("分ごと")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(minWidth: 100)

                    stepButton(systemImage: "plus") {
                        settings.intervalMinutes = min(180, settings.intervalMinutes + 5)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(presetIntervals, id: \.self) { minutes in
                        presetChip(minutes: minutes)
                    }
                }
            }
        }
    }

    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    private func presetChip(minutes: Int) -> some View {
        let isSelected = settings.intervalMinutes == minutes
        return Button {
            settings.intervalMinutes = minutes
        } label: {
            Text("\(minutes)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accent : Color.white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Power card

    private var powerCard: some View {
        CardContainer(title: "タイマー", systemImage: "power") {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.isEnabled ? "稼働中" : "停止中")
                            .font(.headline)
                            .foregroundStyle(settings.isEnabled ? Color.accent : .white.opacity(0.6))
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Toggle("", isOn: $settings.isEnabled)
                        .labelsHidden()
                        .tint(.accent)
                        .scaleEffect(1.1)
                }
            }
        }
    }

    private var statusMessage: String {
        guard settings.isEnabled else { return "オンにすると通知が開始されます" }
        if let next = settings.nextFireDate(from: now) {
            return "次の通知: \(Self.timeFormatter.string(from: next))"
        }
        return "時間帯外です"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// MARK: - Card container

private struct CardContainer<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.06))
        )
    }
}

#Preview {
    ContentView()
}
