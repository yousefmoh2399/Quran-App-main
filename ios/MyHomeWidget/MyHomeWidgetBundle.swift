import WidgetKit
import SwiftUI

@main
struct MyHomeWidgetBundle: WidgetBundle {
    var body: some Widget {
        MyHomeWidget()
        PrayerTimesWidget()
        WirdKhatmaWidget()
    }
}
