//
//  KaloriqWidget2LiveActivity.swift
//  KaloriqWidget2
//
//  Created by Alex Polan on 8/18/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct KaloriqWidget2Attributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct KaloriqWidget2LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KaloriqWidget2Attributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension KaloriqWidget2Attributes {
    fileprivate static var preview: KaloriqWidget2Attributes {
        KaloriqWidget2Attributes(name: "World")
    }
}

extension KaloriqWidget2Attributes.ContentState {
    fileprivate static var smiley: KaloriqWidget2Attributes.ContentState {
        KaloriqWidget2Attributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: KaloriqWidget2Attributes.ContentState {
         KaloriqWidget2Attributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: KaloriqWidget2Attributes.preview) {
   KaloriqWidget2LiveActivity()
} contentStates: {
    KaloriqWidget2Attributes.ContentState.smiley
    KaloriqWidget2Attributes.ContentState.starEyes
}
