import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .init())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: .init())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries: [SimpleEntry] = [SimpleEntry(date: .init())]
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct RAWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            Image(.lockScreenWidgetLogo)
                .resizable()
                .scaledToFit()
                .padding(2)
                .privacySensitive(false)
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct RAWidget: Widget {
    let kind: String = "RAWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RAWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("クイックアクセス")
        .description("ロック画面からアプリを開くことができます。")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    RAWidget()
} timeline: {
    SimpleEntry(date: .now)
}
