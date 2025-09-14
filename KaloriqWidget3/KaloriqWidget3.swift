//
//  KaloriqWidget3.swift (Large Widget - Full Overview)
//  KaloriqWidget3
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
        
        // Update every 15 minutes for large widget (detailed view)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadWidgetData() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.kaloriq.shared") else {
            print("❌ Widget3: Failed to access shared UserDefaults")
            return nil
        }
        
        guard let widgetDataString = sharedDefaults.string(forKey: "widgetData") else {
            print("❌ Widget3: No widget data found")
            return nil
        }
        
        guard let data = widgetDataString.data(using: .utf8) else {
            print("❌ Widget3: Failed to convert data")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let widgetData = try decoder.decode(WidgetData.self, from: data)
            print("✅ Widget3: Loaded data - \(widgetData.calories.current) kcal")
            return widgetData
        } catch {
            print("❌ Widget3: Decode error: \(error)")
            return nil
        }
    }
}

// MARK: - Large Widget View
struct KaloriqWidget3EntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        let calories = entry.widgetData?.calories.current ?? 0
        let target = entry.widgetData?.calories.target ?? 2500
        let remaining = entry.widgetData?.calories.remaining ?? 0
        let calorieProgress = entry.widgetData?.calories.progress ?? 0.0
        let streak = entry.widgetData?.streak ?? 0
        let foods = entry.widgetData?.todayFoods ?? []
        
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
            
            VStack(spacing: 14) {
                // Header Row
                HStack {
                    HStack {
                        Text("Kal")
                            .foregroundColor(Color(red: 0.0, green: 0.44, blue: 0.32))
                        Text("oriq")
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    // Streak Badge
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text("\(streak)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }
                
                // Main Content
                HStack(spacing: 16) {
                    // Left Side - Calories & Status
                    VStack(spacing: 12) {
                        // Calorie Ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: min(calorieProgress, 1.0))
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: calorieProgress)
                            
                            VStack(spacing: 2) {
                                Text("\(calories)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("kcal")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Remaining Calories
                        VStack(spacing: 2) {
                            Text("Remaining")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(remaining)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(remaining > 0 ? .white : .orange)
                        }
                    }
                    
                    // Right Side - Macros & Recent Foods
                    VStack(spacing: 12) {
                        // Macros Row
                        HStack(spacing: 12) {
                            MacroProgressView(
                                current: protein,
                                progress: proteinProgress,
                                color: Color(red: 1.0, green: 0.42, blue: 0.42),
                                label: "P"
                            )
                            MacroProgressView(
                                current: carbs,
                                progress: carbsProgress,
                                color: Color(red: 1.0, green: 0.65, blue: 0.15),
                                label: "C"
                            )
                            MacroProgressView(
                                current: fats,
                                progress: fatsProgress,
                                color: Color(red: 0.26, green: 0.65, blue: 0.96),
                                label: "F"
                            )
                        }
                        
                        // Recent Foods
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Recent Foods")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                            
                            if foods.isEmpty {
                                Text("No foods logged yet")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                                    .italic()
                            } else {
                                ForEach(Array(foods.prefix(3).enumerated()), id: \.offset) { index, food in
                                    FoodItemView(food: food)
                                }
                            }
                        }
                    }
                }
                
                // Bottom Summary
                HStack {
                    let avgProgress = (proteinProgress + carbsProgress + fatsProgress) / 3.0
                    Text("Macro Progress: \(Int(avgProgress * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(formatLastUpdate(entry.widgetData?.lastUpdated))
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding()
        }
    }
    
    private func formatLastUpdate(_ lastUpdated: String?) -> String {
        guard let lastUpdated = lastUpdated else { return "No data" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: lastUpdated) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return "Updated \(timeFormatter.string(from: date))"
        }
        
        return "Updated recently"
    }
}

// MARK: - Helper Views
struct MacroProgressView: View {
    let current: Int
    let progress: Double
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 30, height: 30)
                
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("\(current)g")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(color)
        }
    }
}

struct FoodItemView: View {
    let food: WidgetFood
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 6, height: 6)
            
            Text(food.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(food.calories)")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("kcal")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Widget Configuration
struct KaloriqWidget3: Widget {
    let kind: String = "KaloriqWidget3"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            KaloriqWidget3EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kaloriq Overview")
        .description("Complete nutrition overview with calories, macros, streak, and recent foods.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Preview
/*#Preview(as: .systemLarge) {
    KaloriqWidget3()
} timeline: {
    Provider().placeholder(in: .init())
}
*/
