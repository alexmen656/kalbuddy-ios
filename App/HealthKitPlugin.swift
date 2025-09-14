import Foundation
import Capacitor
import HealthKit

/**
 * HealthKit Plugin for Capacitor
 * Provides integration with Apple HealthKit for reading and writing health data
 */
@objc(HealthKitPlugin)
public class HealthKitPlugin: CAPPlugin {
    public override func load() {
        print("HealthKit plugin loaded successfully")
    }
    
    private let healthStore = HKHealthStore()
    
    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": value
        ])
    }
    
    @objc func isAvailable(_ call: CAPPluginCall) {
        print("HealthKit isAvailable called")
        let available = HKHealthStore.isHealthDataAvailable()
        print("HealthKit available: \(available)")
        call.resolve(["available": available])
    }
    
    @objc func requestPermissions(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.reject("HealthKit is not available on this device")
            return
        }
        
        // Data types we want to read
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        // Data types we want to write
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!
        ]
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    call.resolve(["success": true])
                } else {
                    call.reject("Permission request failed", error?.localizedDescription)
                }
            }
        }
    }
    
    @objc func writeCalories(_ call: CAPPluginCall) {
        guard let calories = call.getDouble("calories") else {
            call.reject("Missing calories parameter")
            return
        }
        
        let date = call.getString("date") ?? ""
        let sampleDate: Date
        
        if !date.isEmpty {
            let formatter = ISO8601DateFormatter()
            sampleDate = formatter.date(from: date) ?? Date()
        } else {
            sampleDate = Date()
        }
        
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            call.reject("Could not create energy type")
            return
        }
        
        let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: sampleDate, end: sampleDate)
        
        healthStore.save(energySample) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    call.resolve(["success": true])
                } else {
                    call.reject("Failed to save calories", error?.localizedDescription)
                }
            }
        }
    }
    
    @objc func readCalories(_ call: CAPPluginCall) {
        let days = call.getInt("days") ?? 7
        
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            call.reject("Could not create energy type")
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: energyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Query failed", error.localizedDescription)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    call.resolve(["samples": []])
                    return
                }
                
                let results = samples.map { sample in
                    return [
                        "value": sample.quantity.doubleValue(for: HKUnit.kilocalorie()),
                        "date": ISO8601DateFormatter().string(from: sample.startDate)
                    ]
                }
                
                call.resolve(["samples": results])
            }
        }
        
        healthStore.execute(query)
    }
    
    @objc func writeWeight(_ call: CAPPluginCall) {
        guard let weight = call.getDouble("weight") else {
            call.reject("Missing weight parameter")
            return
        }
        
        let date = call.getString("date") ?? ""
        let sampleDate: Date
        
        if !date.isEmpty {
            let formatter = ISO8601DateFormatter()
            sampleDate = formatter.date(from: date) ?? Date()
        } else {
            sampleDate = Date()
        }
        
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            call.reject("Could not create weight type")
            return
        }
        
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: sampleDate, end: sampleDate)
        
        healthStore.save(weightSample) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    call.resolve(["success": true])
                } else {
                    call.reject("Failed to save weight", error?.localizedDescription)
                }
            }
        }
    }
    
    @objc func readWeight(_ call: CAPPluginCall) {
        let days = call.getInt("days") ?? 30
        
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            call.reject("Could not create weight type")
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Query failed", error.localizedDescription)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    call.resolve(["samples": []])
                    return
                }
                
                let results = samples.map { sample in
                    return [
                        "value": sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)),
                        "date": ISO8601DateFormatter().string(from: sample.startDate)
                    ]
                }
                
                call.resolve(["samples": results])
            }
        }
        
        healthStore.execute(query)
    }
    
    @objc func writeWater(_ call: CAPPluginCall) {
        guard let water = call.getDouble("water") else {
            call.reject("Missing water parameter")
            return
        }
        
        let date = call.getString("date") ?? ""
        let sampleDate: Date
        
        if !date.isEmpty {
            let formatter = ISO8601DateFormatter()
            sampleDate = formatter.date(from: date) ?? Date()
        } else {
            sampleDate = Date()
        }
        
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            call.reject("Could not create water type")
            return
        }
        
        let waterQuantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: water)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: sampleDate, end: sampleDate)
        
        healthStore.save(waterSample) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    call.resolve(["success": true])
                } else {
                    call.reject("Failed to save water", error?.localizedDescription)
                }
            }
        }
    }
    
    @objc func readWater(_ call: CAPPluginCall) {
        let days = call.getInt("days") ?? 7
        
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            call.reject("Could not create water type")
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: waterType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Query failed", error.localizedDescription)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    call.resolve(["samples": []])
                    return
                }
                
                let results = samples.map { sample in
                    return [
                        "value": sample.quantity.doubleValue(for: HKUnit.literUnit(with: .milli)),
                        "date": ISO8601DateFormatter().string(from: sample.startDate)
                    ]
                }
                
                call.resolve(["samples": results])
            }
        }
        
        healthStore.execute(query)
    }
    
    @objc func writeMacros(_ call: CAPPluginCall) {
        guard let protein = call.getDouble("protein"),
              let carbs = call.getDouble("carbs"),
              let fat = call.getDouble("fat") else {
            call.reject("Missing macro parameters")
            return
        }
        
        let date = call.getString("date") ?? ""
        let sampleDate: Date
        
        if !date.isEmpty {
            let formatter = ISO8601DateFormatter()
            sampleDate = formatter.date(from: date) ?? Date()
        } else {
            sampleDate = Date()
        }
        
        guard let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
              let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
              let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) else {
            call.reject("Could not create macro types")
            return
        }
        
        let proteinQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: protein)
        let carbsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: carbs)
        let fatQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: fat)
        
        let proteinSample = HKQuantitySample(type: proteinType, quantity: proteinQuantity, start: sampleDate, end: sampleDate)
        let carbsSample = HKQuantitySample(type: carbsType, quantity: carbsQuantity, start: sampleDate, end: sampleDate)
        let fatSample = HKQuantitySample(type: fatType, quantity: fatQuantity, start: sampleDate, end: sampleDate)
        
        healthStore.save([proteinSample, carbsSample, fatSample]) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    call.resolve(["success": true])
                } else {
                    call.reject("Failed to save macros", error?.localizedDescription)
                }
            }
        }
    }
    
    @objc func readMacros(_ call: CAPPluginCall) {
        let days = call.getInt("days") ?? 7
        
        guard let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
              let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
              let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) else {
            call.reject("Could not create macro types")
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let group = DispatchGroup()
        var proteinSamples: [HKQuantitySample] = []
        var carbsSamples: [HKQuantitySample] = []
        var fatSamples: [HKQuantitySample] = []
        var hasError = false
        var errorMessage = ""
        
        // Query protein
        group.enter()
        let proteinQuery = HKSampleQuery(sampleType: proteinType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            if let error = error {
                hasError = true
                errorMessage = error.localizedDescription
            } else if let samples = samples as? [HKQuantitySample] {
                proteinSamples = samples
            }
            group.leave()
        }
        healthStore.execute(proteinQuery)
        
        // Query carbs
        group.enter()
        let carbsQuery = HKSampleQuery(sampleType: carbsType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            if let error = error {
                hasError = true
                errorMessage = error.localizedDescription
            } else if let samples = samples as? [HKQuantitySample] {
                carbsSamples = samples
            }
            group.leave()
        }
        healthStore.execute(carbsQuery)
        
        // Query fat
        group.enter()
        let fatQuery = HKSampleQuery(sampleType: fatType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            if let error = error {
                hasError = true
                errorMessage = error.localizedDescription
            } else if let samples = samples as? [HKQuantitySample] {
                fatSamples = samples
            }
            group.leave()
        }
        healthStore.execute(fatQuery)
        
        group.notify(queue: .main) {
            if hasError {
                call.reject("Query failed", errorMessage)
                return
            }
            
            let proteinResults = proteinSamples.map { sample in
                return [
                    "value": sample.quantity.doubleValue(for: HKUnit.gram()),
                    "date": ISO8601DateFormatter().string(from: sample.startDate)
                ]
            }
            
            let carbsResults = carbsSamples.map { sample in
                return [
                    "value": sample.quantity.doubleValue(for: HKUnit.gram()),
                    "date": ISO8601DateFormatter().string(from: sample.startDate)
                ]
            }
            
            let fatResults = fatSamples.map { sample in
                return [
                    "value": sample.quantity.doubleValue(for: HKUnit.gram()),
                    "date": ISO8601DateFormatter().string(from: sample.startDate)
                ]
            }
            
            call.resolve([
                "protein": proteinResults,
                "carbs": carbsResults,
                "fat": fatResults
            ])
        }
    }
    
    @objc func readSteps(_ call: CAPPluginCall) {
        let days = call.getInt("days") ?? 7
        
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            call.reject("Could not create steps type")
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: stepsType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Query failed", error.localizedDescription)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    call.resolve(["samples": []])
                    return
                }
                
                let results = samples.map { sample in
                    return [
                        "value": sample.quantity.doubleValue(for: HKUnit.count()),
                        "date": ISO8601DateFormatter().string(from: sample.startDate)
                    ]
                }
                
                call.resolve(["samples": results])
            }
        }
        
        healthStore.execute(query)
    }
    
    @objc func requestPermissions(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.reject("HealthKit is not available on this device")
            return
        }
        
        let readTypes = getHealthKitTypes(from: call.getArray("read", String.self) ?? [])
        let writeTypes = getHealthKitTypes(from: call.getArray("write", String.self) ?? [])
        
        let allTypes = Set(readTypes + writeTypes)
        
        healthStore.requestAuthorization(toShare: Set(writeTypes), read: Set(readTypes)) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Failed to request permissions: \(error.localizedDescription)")
                } else {
                    call.resolve(["granted": success])
                }
            }
        }
    }
    
    @objc func writeCalories(_ call: CAPPluginCall) {
        guard let calories = call.getDouble("calories") else {
            call.reject("Calories value is required")
            return
        }
        
        let dateString = call.getString("date")
        let date = dateString != nil ? ISO8601DateFormatter().date(from: dateString!) ?? Date() : Date()
        
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let calorieQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        let calorieSample = HKQuantitySample(type: calorieType, quantity: calorieQuantity, start: date, end: date)
        
        healthStore.save(calorieSample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Failed to save calories: \(error.localizedDescription)")
                } else {
                    call.resolve(["success": success])
                }
            }
        }
    }
    
    @objc func readCalories(_ call: CAPPluginCall) {
        let startDateString = call.getString("startDate")
        let endDateString = call.getString("endDate")
        
        let startDate = startDateString != nil ? ISO8601DateFormatter().date(from: startDateString!) : Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = endDateString != nil ? ISO8601DateFormatter().date(from: endDateString!) : Date()
        
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: calorieType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Failed to read calories: \(error.localizedDescription)")
                    return
                }
                
                var calorieEntries: [[String: Any]] = []
                
                if let samples = samples as? [HKQuantitySample] {
                    for sample in samples {
                        let calories = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                        let date = ISO8601DateFormatter().string(from: sample.startDate)
                        let source = sample.sourceRevision.source.name
                        
                        calorieEntries.append([
                            "calories": calories,
                            "date": date,
                            "source": source
                        ])
                    }
                }
                
                call.resolve(["calories": calorieEntries])
            }
        }
        
        healthStore.execute(query)
    }
    
    @objc func writeWeight(_ call: CAPPluginCall) {
        guard let weight = call.getDouble("weight") else {
            call.reject("Weight value is required")
            return
        }
        
        let unitString = call.getString("unit") ?? "kg"
        let dateString = call.getString("date")
        let date = dateString != nil ? ISO8601DateFormatter().date(from: dateString!) ?? Date() : Date()
        
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let unit = unitString == "lb" ? HKUnit.pound() : HKUnit.gramUnit(with: .kilo)
        let weightQuantity = HKQuantity(unit: unit, doubleValue: weight)
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: date, end: date)
        
        healthStore.save(weightSample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Failed to save weight: \(error.localizedDescription)")
                } else {
                    call.resolve(["success": success])
                }
            }
        }
    }
    
    @objc func readWeight(_ call: CAPPluginCall) {
        let startDateString = call.getString("startDate")
        let endDateString = call.getString("endDate")
        
        let startDate = startDateString != nil ? ISO8601DateFormatter().date(from: startDateString!) : Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let endDate = endDateString != nil ? ISO8601DateFormatter().date(from: endDateString!) : Date()
        
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Failed to read weight: \(error.localizedDescription)")
                    return
                }
                
                var weightEntries: [[String: Any]] = []
                
                if let samples = samples as? [HKQuantitySample] {
                    for sample in samples {
                        let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                        let date = ISO8601DateFormatter().string(from: sample.startDate)
                        let source = sample.sourceRevision.source.name
                        
                        weightEntries.append([
                            "weight": weightInKg,
                            "unit": "kg",
                            "date": date,
                            "source": source
                        ])
                    }
                }
                
                call.resolve(["weights": weightEntries])
            }
        }
        
        healthStore.execute(query)
    }
    
    @objc func writeWater(_ call: CAPPluginCall) {
        guard let volume = call.getDouble("volume") else {
            call.reject("Volume value is required")
            return
        }
        
        let unitString = call.getString("unit") ?? "ml"
        let dateString = call.getString("date")
        let date = dateString != nil ? ISO8601DateFormatter().date(from: dateString!) ?? Date() : Date()
        
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let unit: HKUnit
        
        switch unitString {
        case "l":
            unit = HKUnit.liter()
        case "fl_oz":
            unit = HKUnit.fluidOunceUS()
        default:
            unit = HKUnit.literUnit(with: .milli)
        }
        
        let waterQuantity = HKQuantity(unit: unit, doubleValue: volume)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: date, end: date)
        
        healthStore.save(waterSample) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Failed to save water: \(error.localizedDescription)")
                } else {
                    call.resolve(["success": success])
                }
            }
        }
    }
    
    @objc func readWater(_ call: CAPPluginCall) {
        let startDateString = call.getString("startDate")
        let endDateString = call.getString("endDate")
        
        let startDate = startDateString != nil ? ISO8601DateFormatter().date(from: startDateString!) : Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = endDateString != nil ? ISO8601DateFormatter().date(from: endDateString!) : Date()
        
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: waterType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Failed to read water: \(error.localizedDescription)")
                    return
                }
                
                var waterEntries: [[String: Any]] = []
                
                if let samples = samples as? [HKQuantitySample] {
                    for sample in samples {
                        let volumeInML = sample.quantity.doubleValue(for: HKUnit.literUnit(with: .milli))
                        let date = ISO8601DateFormatter().string(from: sample.startDate)
                        let source = sample.sourceRevision.source.name
                        
                        waterEntries.append([
                            "volume": volumeInML,
                            "unit": "ml",
                            "date": date,
                            "source": source
                        ])
                    }
                }
                
                call.resolve(["water": waterEntries])
            }
        }
        
        healthStore.execute(query)
    }
    
    @objc func writeNutrition(_ call: CAPPluginCall) {
        let dateString = call.getString("date")
        let date = dateString != nil ? ISO8601DateFormatter().date(from: dateString!) ?? Date() : Date()
        
        var samplesToSave: [HKQuantitySample] = []
        
        // Protein
        if let protein = call.getDouble("protein") {
            let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            let proteinQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: protein)
            let proteinSample = HKQuantitySample(type: proteinType, quantity: proteinQuantity, start: date, end: date)
            samplesToSave.append(proteinSample)
        }
        
        // Carbohydrates
        if let carbs = call.getDouble("carbohydrates") {
            let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            let carbsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: carbs)
            let carbsSample = HKQuantitySample(type: carbsType, quantity: carbsQuantity, start: date, end: date)
            samplesToSave.append(carbsSample)
        }
        
        // Fat
        if let fat = call.getDouble("fat") {
            let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
            let fatQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: fat)
            let fatSample = HKQuantitySample(type: fatType, quantity: fatQuantity, start: date, end: date)
            samplesToSave.append(fatSample)
        }
        
        // Fiber
        if let fiber = call.getDouble("fiber") {
            let fiberType = HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!
            let fiberQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: fiber)
            let fiberSample = HKQuantitySample(type: fiberType, quantity: fiberQuantity, start: date, end: date)
            samplesToSave.append(fiberSample)
        }
        
        // Sugar
        if let sugar = call.getDouble("sugar") {
            let sugarType = HKQuantityType.quantityType(forIdentifier: .dietarySugar)!
            let sugarQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: sugar)
            let sugarSample = HKQuantitySample(type: sugarType, quantity: sugarQuantity, start: date, end: date)
            samplesToSave.append(sugarSample)
        }
        
        // Sodium
        if let sodium = call.getDouble("sodium") {
            let sodiumType = HKQuantityType.quantityType(forIdentifier: .dietarySodium)!
            let sodiumQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .milli), doubleValue: sodium)
            let sodiumSample = HKQuantitySample(type: sodiumType, quantity: sodiumQuantity, start: date, end: date)
            samplesToSave.append(sodiumSample)
        }
        
        guard !samplesToSave.isEmpty else {
            call.reject("No nutrition data provided")
            return
        }
        
        healthStore.save(samplesToSave) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("Failed to save nutrition data: \(error.localizedDescription)")
                } else {
                    call.resolve(["success": success])
                }
            }
        }
    }
    
    @objc func readNutrition(_ call: CAPPluginCall) {
        let startDateString = call.getString("startDate")
        let endDateString = call.getString("endDate")
        
        let startDate = startDateString != nil ? ISO8601DateFormatter().date(from: startDateString!) : Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = endDateString != nil ? ISO8601DateFormatter().date(from: endDateString!) : Date()
        
        let nutritionTypes: [HKQuantityTypeIdentifier] = [
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFatTotal,
            .dietaryFiber,
            .dietarySugar,
            .dietarySodium
        ]
        
        let group = DispatchGroup()
        var nutritionData: [String: [[String: Any]]] = [:]
        var hasError = false
        var errorMessage = ""
        
        for typeIdentifier in nutritionTypes {
            group.enter()
            
            let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier)!
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
            
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    hasError = true
                    errorMessage = error.localizedDescription
                    group.leave()
                    return
                }
                
                var entries: [[String: Any]] = []
                
                if let samples = samples as? [HKQuantitySample] {
                    for sample in samples {
                        let unit = typeIdentifier == .dietarySodium ? HKUnit.gramUnit(with: .milli) : HKUnit.gram()
                        let value = sample.quantity.doubleValue(for: unit)
                        let date = ISO8601DateFormatter().string(from: sample.startDate)
                        let source = sample.sourceRevision.source.name
                        
                        entries.append([
                            "value": value,
                            "date": date,
                            "source": source
                        ])
                    }
                }
                
                nutritionData[typeIdentifier.rawValue] = entries
                group.leave()
            }
            
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            if hasError {
                call.reject("Failed to read nutrition data: \(errorMessage)")
            } else {
                call.resolve(["nutrition": nutritionData])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getHealthKitTypes(from strings: [String]) -> [HKQuantityType] {
        var types: [HKQuantityType] = []
        
        for string in strings {
            switch string {
            case "calories":
                if let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                    types.append(type)
                }
            case "weight":
                if let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
                    types.append(type)
                }
            case "water":
                if let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
                    types.append(type)
                }
            case "protein":
                if let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
                    types.append(type)
                }
            case "carbohydrates":
                if let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
                    types.append(type)
                }
            case "fat":
                if let type = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
                    types.append(type)
                }
            case "fiber":
                if let type = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
                    types.append(type)
                }
            case "sugar":
                if let type = HKQuantityType.quantityType(forIdentifier: .dietarySugar) {
                    types.append(type)
                }
            case "sodium":
                if let type = HKQuantityType.quantityType(forIdentifier: .dietarySodium) {
                    types.append(type)
                }
            default:
                break
            }
        }
        
        return types
    }
}
