//
//  KaloriqWidgetBundle.swift
//  KaloriqWidget
//
//  Created by Alex Polan on 8/18/25.
//

import WidgetKit
import SwiftUI

@main
struct KaloriqWidgetBundle: WidgetBundle {
    var body: some Widget {
        KaloriqWidget()
        KaloriqWidgetControl()
        KaloriqWidgetLiveActivity()
    }
}
