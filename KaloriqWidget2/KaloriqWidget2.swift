//
//  KaloriqWidget2.swift (Medium Widget - Macros Focus)
//  KaloriqWidget2
//
//  Created by Alex Polan on 8/18/25.
//

import WidgetKit
import SwiftUI

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
            calories: WidgetData.CalorieData(current: 1950, target: 2500, progress: 0.78, remaining: 550),
            macros: WidgetData.MacroData(
                protein: WidgetData.MacroData.MacroDetail(current: 135, target: 150, progress: 0.9),
                carbs: WidgetData.MacroData.MacroDetail(current: 210, target: 300, progress: 0.7),
                fats: WidgetData.MacroData.MacroDetail(current: 70, target: 80, progress: 0.875)
            ),
            streak: 18,
            lastUpdated: "2025-08-18T14:30:00Z",
            todayFoods: [
                WidgetFood(name: "Salmon Fillet", calories: 420, time: "13:15"),
                WidgetFood(name: "Quinoa Bowl", calories: 380, time: "13:15"),
                WidgetFood(name: "Protein Shake", calories: 180, time: "10:30")
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
        
        // Update every 10 minutes for medium widget (more frequent for macro tracking)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadWidgetData() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.kaloriq.shared") else {
            print("❌ Widget2: Failed to access shared UserDefaults")
            return nil
        }
        
        guard let widgetDataString = sharedDefaults.string(forKey: "widgetData") else {
            print("❌ Widget2: No widget data found")
            return nil
        }
        
        guard let data = widgetDataString.data(using: .utf8) else {
            print("❌ Widget2: Failed to convert data")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let widgetData = try decoder.decode(WidgetData.self, from: data)
            print("✅ Widget2: Loaded data - \(widgetData.calories.current) kcal")
            return widgetData
        } catch {
            print("❌ Widget2: Decode error: \(error)")
            return nil
        }
    }
}

// MARK: - Widget View (Medium Focus)
struct KaloriqWidget2EntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCaloriesWidget2(entry: entry)
        default:
            let calories = entry.widgetData?.calories.current ?? 0
            let target = entry.widgetData?.calories.target ?? 2500
            let calorieProgress = entry.widgetData?.calories.progress ?? 0.0
            
            let protein = entry.widgetData?.macros.protein.current ?? 0
            let carbs = entry.widgetData?.macros.carbs.current ?? 0
            let fats = entry.widgetData?.macros.fats.current ?? 0
            
            let proteinTarget = entry.widgetData?.macros.protein.target ?? 150
            let carbsTarget = entry.widgetData?.macros.carbs.target ?? 300
            let fatsTarget = entry.widgetData?.macros.fats.target ?? 80
            
            let proteinProgress = entry.widgetData?.macros.protein.progress ?? 0.0
            let carbsProgress = entry.widgetData?.macros.carbs.progress ?? 0.0
            let fatsProgress = entry.widgetData?.macros.fats.progress ?? 0.0

            ZStack {
                // Full background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.18),
                        Color(red: 0.16, green: 0.18, blue: 0.22)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                       .frame(maxWidth: .infinity, maxHeight: .infinity)
                       .clipped()
                
                GeometryReader { geometry in
                    HStack(spacing: 20) {
                        // Calories Section - Left side
                        VStack(spacing: 4) {
                            let circleSize = min(geometry.size.height * 0.75, geometry.size.width * 0.4)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                                    .frame(width: circleSize, height: circleSize)
                                
                                Circle()
                                    .trim(from: 0, to: min(calorieProgress, 1.0))
                                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: circleSize, height: circleSize)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 1.0), value: calorieProgress)
                                
                                VStack(spacing: 1) {
                                    Text("\(calories)")
                                        .font(.system(size: circleSize * 0.18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("kcal")
                                        .font(.system(size: circleSize * 0.09))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        
                        // Macros Grid - Right side
                        VStack(spacing: 16) {
                            // Top Row
                            HStack(spacing: 16) {
                                MacroDetailView(
                                    current: protein,
                                    target: proteinTarget,
                                    progress: proteinProgress,
                                    color: Color(red: 1.0, green: 0.42, blue: 0.42),
                                    label: "Protein",
                                    size: geometry.size
                                )
                                MacroDetailView(
                                    current: carbs,
                                    target: carbsTarget,
                                    progress: carbsProgress,
                                    color: Color(red: 1.0, green: 0.65, blue: 0.15),
                                    label: "Carbs",
                                    size: geometry.size
                                )
                            }
                            
                            // Bottom Row
                            HStack(spacing: 16) {
                                MacroDetailView(
                                    current: fats,
                                    target: fatsTarget,
                                    progress: fatsProgress,
                                    color: Color(red: 0.26, green: 0.65, blue: 0.96),
                                    label: "Fats",
                                    size: geometry.size
                                )
                                
                                // Progress Summary
                                VStack(spacing: 4) {
                                    Text("Progress")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    let avgProgress = (proteinProgress + carbsProgress + fatsProgress) / 3.0
                                    Text("\(Int(avgProgress * 100))%")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(minWidth: 50)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

// MARK: - Small Widget
struct SmallCaloriesWidget2: View {
    let entry: KaloriqEntry
    
    var body: some View {
        let calories = entry.widgetData?.calories.current ?? 0
        let target = entry.widgetData?.calories.target ?? 2500
        let progress = entry.widgetData?.calories.progress ?? 0.0
        
        ZStack {
      /*      LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.18),
                    Color(red: 0.16, green: 0.18, blue: 0.22)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .containerBackground(for: .widget) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.18),
                        Color(red: 0.16, green: 0.18, blue: 0.22)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }*/
            
            VStack(spacing: 8) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 16)
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: progress)
                    
                    VStack(spacing: 2) {
                        Text("\(calories)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("of \(target) kcal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct MacroDetailView: View {
    let current: Int
    let target: Int
    let progress: Double
    let color: Color
    let label: String
    let size: CGSize
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(current)g")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            // Larger progress bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.2))
                .frame(width: 50, height: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: 50 * min(progress, 1.0), height: 6)
                        .animation(.easeInOut(duration: 1.0), value: progress),
                    alignment: .leading
                )
        }
        .frame(minWidth: 50)
    }
}


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

// MARK: - Widget Configuration
struct KaloriqWidget2: Widget {
    let kind: String = "KaloriqWidget2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            KaloriqWidget2EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kaloriq Macros")
        .description("Track your daily macronutrients with detailed protein, carbs, and fats progress. 222")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabledIfAvailable() // <- Das ist der wichtige Teil!

    }
}

// MARK: - Preview
/*#Preview(as: .systemMedium) {
    KaloriqWidget2()
} timeline: {
    Provider().placeholder(in: .init())
}
*/
