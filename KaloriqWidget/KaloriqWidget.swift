//
//  KaloriqWidget.swift
//  KaloriqWidget
//
//  Created by Alex Polan on 8/18/25.
//

import WidgetKit
import SwiftUI

// MARK: - Extension to disable content margins
extension WidgetConfiguration {
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

// MARK: - Data Models
struct WidgetData: Codable {
    let calories: CalorieData
    let macros: MacroData
    let streak: Int
    let lastUpdated: String
    let todayFoods: [WidgetFood]
    
    struct CalorieData: Codable {
        let current: Int
        let target: Int
        let progress: Double
        let remaining: Int
    }
    
    struct MacroData: Codable {
        let protein: MacroDetail
        let carbs: MacroDetail
        let fats: MacroDetail
        
        struct MacroDetail: Codable {
            let current: Int
            let target: Int
            let progress: Double
        }
    }
}

struct WidgetFood: Codable {
    let name: String
    let calories: Int
    let time: String
}

// MARK: - Widget Entry
struct KaloriqEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData?
}

// MARK: - Widget Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> KaloriqEntry {
        let mockData = WidgetData(
            calories: WidgetData.CalorieData(current: 1800, target: 2500, progress: 0.72, remaining: 700),
            macros: WidgetData.MacroData(
                protein: WidgetData.MacroData.MacroDetail(current: 120, target: 150, progress: 0.8),
                carbs: WidgetData.MacroData.MacroDetail(current: 180, target: 300, progress: 0.6),
                fats: WidgetData.MacroData.MacroDetail(current: 60, target: 80, progress: 0.75)
            ),
            streak: 15,
            lastUpdated: "2025-08-18T12:00:00Z",
            todayFoods: [
                WidgetFood(name: "Chicken Breast", calories: 350, time: "12:30"),
                WidgetFood(name: "Brown Rice", calories: 220, time: "12:30"),
                WidgetFood(name: "Greek Yogurt", calories: 150, time: "09:00")
            ]
        )
        
        return KaloriqEntry(date: Date(), widgetData: mockData)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (KaloriqEntry) -> ()) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            let entry = KaloriqEntry(date: Date(), widgetData: loadWidgetData())
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<KaloriqEntry>) -> ()) {
        let currentDate = Date()
        let widgetData = loadWidgetData()
        
        let entry = KaloriqEntry(date: currentDate, widgetData: widgetData)
        
        // Update every 15 minutes or when app data changes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadWidgetData() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.kaloriq.shared") else {
            print("❌ Failed to access shared UserDefaults")
            return nil
        }
        
        // Read widget data from Capacitor Preferences stored in shared group
        guard let widgetDataString = sharedDefaults.string(forKey: "widgetData") else {
            print("❌ No widget data found in shared preferences")
            return nil
        }
        
        guard let data = widgetDataString.data(using: .utf8) else {
            print("❌ Failed to convert widget data string to data")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let widgetData = try decoder.decode(WidgetData.self, from: data)
            print("✅ Successfully loaded widget data: \(widgetData.calories.current) calories")
            return widgetData
        } catch {
            print("❌ Failed to decode widget data: \(error)")
            return nil
        }
    }
}

// MARK: - Widget Views
struct KaloriqWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallCaloriesWidget(entry: entry)
        case .systemMedium:
            MediumMacrosWidget(entry: entry)
        case .systemLarge:
            LargeOverviewWidget(entry: entry)
        default:
            SmallCaloriesWidget(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallCaloriesWidget: View {
    let entry: KaloriqEntry
    
    var body: some View {
        let calories = entry.widgetData?.calories.current ?? 0
        let target = entry.widgetData?.calories.target ?? 2500
        let progress = entry.widgetData?.calories.progress ?? 0.0
        
        ZStack {
          /*  ContainerRelativeShape()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.18),
                        Color(red: 0.16, green: 0.18, blue: 0.22)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )) */
            
            VStack(spacing: 8) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 7)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: progress)
                    
                    Image(systemName: "flame.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                
                VStack(spacing: 2) {
                    Text("\(calories)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("of \(target) kcal")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Medium Widget
struct MediumMacrosWidget: View {
    let entry: KaloriqEntry
    
    var body: some View {
        let calories = entry.widgetData?.calories.current ?? 0
        let target = entry.widgetData?.calories.target ?? 2500
        let calorieProgress = entry.widgetData?.calories.progress ?? 0.0
        
        let protein = entry.widgetData?.macros.protein.current ?? 0
        let carbs = entry.widgetData?.macros.carbs.current ?? 0
        let fats = entry.widgetData?.macros.fats.current ?? 0
        
        let proteinProgress = entry.widgetData?.macros.protein.progress ?? 0.0
        let carbsProgress = entry.widgetData?.macros.carbs.progress ?? 0.0
        let fatsProgress = entry.widgetData?.macros.fats.progress ?? 0.0
        
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.18),
                        Color(red: 0.16, green: 0.18, blue: 0.22)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            HStack(spacing: 16) {
                // Calories Section
             /*   VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: min(calorieProgress, 1.0))
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: calorieProgress)
                        
                        Image(systemName: "flame.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(calories)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("kcal")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }*/
                
                // Macros Section
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        MacroRing(
                            value: calories,
                            progress: calorieProgress,
                            color: Color(red: 1.0, green: 1.0, blue: 1.0),
                            label: "kcal"
                        )
                        MacroRing(
                            value: protein,
                            progress: proteinProgress,
                            color: Color(red: 1.0, green: 0.42, blue: 0.42),
                            label: "P"
                        )
                        MacroRing(
                            value: carbs,
                            progress: carbsProgress,
                            color: Color(red: 1.0, green: 0.65, blue: 0.15),
                            label: "C"
                        )
                        MacroRing(
                            value: fats,
                            progress: fatsProgress,
                            color: Color(red: 0.26, green: 0.65, blue: 0.96),
                            label: "F"
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Large Widget
struct LargeOverviewWidget: View {
    let entry: KaloriqEntry
    
    var body: some View {
        let calories = entry.widgetData?.calories.current ?? 0
        let target = entry.widgetData?.calories.target ?? 2500
        let remaining = entry.widgetData?.calories.remaining ?? 0
        let calorieProgress = entry.widgetData?.calories.progress ?? 0.0
        
        let protein = entry.widgetData?.macros.protein.current ?? 0
        let carbs = entry.widgetData?.macros.carbs.current ?? 0
        let fats = entry.widgetData?.macros.fats.current ?? 0
        
        let streak = entry.widgetData?.streak ?? 0
        let recentFoods = entry.widgetData?.todayFoods ?? []
        
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.18),
                        Color(red: 0.16, green: 0.18, blue: 0.22)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(spacing: 16) {
                // Header with streak
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Kal")
                                .foregroundColor(Color(red: 0.0, green: 0.44, blue: 0.32))
                            Text("oriq")
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 18, weight: .bold))
                        
                        Text("Daily Progress")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.21))
                            .font(.system(size: 12))
                        
                        Text("\(streak)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Main calories and macros
                HStack(spacing: 20) {
                    // Calories ring
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 6)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .trim(from: 0, to: min(calorieProgress, 1.0))
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: calorieProgress)
                            
                            VStack(spacing: 2) {
                                Text("\(calories)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("kcal")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Text("\(remaining) left")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Macros grid
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            MacroColumn(
                                value: protein,
                                label: "Protein",
                                color: Color(red: 1.0, green: 0.42, blue: 0.42)
                            )
                            MacroColumn(
                                value: carbs,
                                label: "Carbs",
                                color: Color(red: 1.0, green: 0.65, blue: 0.15)
                            )
                            MacroColumn(
                                value: fats,
                                label: "Fats",
                                color: Color(red: 0.26, green: 0.65, blue: 0.96)
                            )
                        }
                    }
                }
                
                // Recent foods
                if !recentFoods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 4) {
                            ForEach(Array(recentFoods.prefix(3).enumerated()), id: \.offset) { index, food in
                                HStack {
                                    Text(food.name)
                                        .font(.system(size: 11))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(food.calories) kcal")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Helper Views
struct MacroRing: View {
    let value: Int
    let progress: Double
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                Text(label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text("\(value)g")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct MacroColumn: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)g")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Widget Configuration
struct KaloriqWidget: Widget {
    let kind: String = "KaloriqWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            KaloriqWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kaloriq")
        .description("Track your daily nutrition goals with live calorie and macro progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabledIfAvailable() // <- Das ist der wichtige Teil!
    }
}

// MARK: - Preview
/*#Preview(as: .systemSmall) {
    KaloriqWidget()
} timeline: {
    Provider().placeholder(in: .init())
}

#Preview(as: .systemMedium) {
    KaloriqWidget()
} timeline: {
    Provider().placeholder(in: .init())
}

#Preview(as: .systemLarge) {
    KaloriqWidget()
} timeline: {
    Provider().placeholder(in: .init())
}*/
