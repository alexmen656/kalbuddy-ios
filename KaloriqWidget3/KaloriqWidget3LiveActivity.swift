//
//  KaloriqWidget3LiveActivity.swift
//  KaloriqWidget3
//
//  Created by Alex Polan on 8/18/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct KaloriqWidget3Attributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct KaloriqWidget3LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KaloriqWidget3Attributes.self) { context in
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

extension KaloriqWidget3Attributes {
    fileprivate static var preview: KaloriqWidget3Attributes {
        KaloriqWidget3Attributes(name: "World")
    }
}

extension KaloriqWidget3Attributes.ContentState {
    fileprivate static var smiley: KaloriqWidget3Attributes.ContentState {
        KaloriqWidget3Attributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: KaloriqWidget3Attributes.ContentState {
         KaloriqWidget3Attributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: KaloriqWidget3Attributes.preview) {
   KaloriqWidget3LiveActivity()
} contentStates: {
    KaloriqWidget3Attributes.ContentState.smiley
    KaloriqWidget3Attributes.ContentState.starEyes
}
