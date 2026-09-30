import WidgetKit
import SwiftUI

// MARK: - Data Models
struct AzkarWidgetItem: Codable {
    let id: Int
    let text: String
    let category: String
    let category_name: String
    let source: String
    let count: Int
}

class AzkarDataLoader {
    static let shared = AzkarDataLoader()
    private(set) var azkarList: [AzkarWidgetItem] = []

    init() {
        loadData()
    }

    private func loadData() {
        // Look for bundled JSON in Widget extension bundle or main bundle
        let possibleUrls = [
            Bundle.main.url(forResource: "azkar_widget_data", withExtension: "json"),
            Bundle(for: AzkarDataLoader.self).url(forResource: "azkar_widget_data", withExtension: "json")
        ]

        for url in possibleUrls.compactMap({ $0 }) {
            if let data = try? Data(contentsOf: url),
               let list = try? JSONDecoder().decode([AzkarWidgetItem].self, from: data),
               !list.isEmpty {
                self.azkarList = list
                return
            }
        }

        // Fallback default list
        self.azkarList = [
            AzkarWidgetItem(
                id: 1,
                text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
                category: "tasbeeh",
                category_name: "تسابيح وتحميد",
                source: "صحيح البخاري: كلمتان خفيفتان على اللسان ثقيلتان في الميزان",
                count: 100
            ),
            AzkarWidgetItem(
                id: 2,
                text: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
                category: "quranic",
                category_name: "أدعية قرآنية",
                source: "سورة البقرة: 201",
                count: 1
            ),
            AzkarWidgetItem(
                id: 3,
                text: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ",
                category: "tasbeeh",
                category_name: "تسابيح وتحميد",
                source: "صحيح البخاري: كنز من كنوز الجنة",
                count: 10
            )
        ]
    }

    func itemFor(date: Date) -> AzkarWidgetItem {
        guard !azkarList.isEmpty else {
            return AzkarWidgetItem(
                id: 1,
                text: "سُبْحَانَ اللَّهِ",
                category: "tasbeeh",
                category_name: "تسابيح",
                source: "البخاري",
                count: 33
            )
        }
        let timeInterval = date.timeIntervalSince1970
        let slot = Int(timeInterval / (10 * 60)) // 10 minutes deterministic slot
        let index = abs(slot) % azkarList.count
        return azkarList[index]
    }
}

// MARK: - Timeline Provider for Azkar
struct AzkarTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AzkarEntry {
        AzkarEntry(
            date: Date(),
            text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
            source: "صحيح البخاري",
            category: "تسابيح وتحميد"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AzkarEntry) -> Void) {
        let item = AzkarDataLoader.shared.itemFor(date: Date())
        let entry = AzkarEntry(
            date: Date(),
            text: item.text,
            source: item.source,
            category: item.category_name
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AzkarEntry>) -> Void) {
        var entries: [AzkarEntry] = []
        let currentDate = Date()
        let calendar = Calendar.current

        // Generate 144 timeline entries ahead of time (every 10 minutes for 24 hours)
        for minuteOffset in stride(from: 0, to: 24 * 60, by: 10) {
            if let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: currentDate) {
                let item = AzkarDataLoader.shared.itemFor(date: entryDate)
                let entry = AzkarEntry(
                    date: entryDate,
                    text: item.text,
                    source: item.source,
                    category: item.category_name
                )
                entries.append(entry)
            }
        }

        // Schedule next reload after 24 hours
        let reloadDate = calendar.date(byAdding: .hour, value: 24, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}

struct AzkarEntry: TimelineEntry {
    let date: Date
    let text: String
    let source: String
    let category: String
}

// MARK: - Azkar Widget View
struct AzkarWidgetEntryView : View {
    var entry: AzkarTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryInline:
            accessoryInlineView
        case .accessoryCircular:
            accessoryCircularView
        default:
            mediumView
        }
    }

    // Small Widget (2x2)
    var smallView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                Spacer()
                Text("ذكر وتذكير 📿")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.36, green: 0.86, blue: 0.71))
            }

            Spacer()

            Text(entry.text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .frame(maxWidth: .infinity)

            Spacer()

            Text(entry.source)
                .font(.system(size: 9))
                .foregroundColor(Color(red: 0.55, green: 0.69, blue: 0.63))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(12)
        .background(emeraldBackground)
    }

    // Medium Widget (4x2)
    var mediumView: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Text(entry.category)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.36, green: 0.86, blue: 0.71))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.16, green: 0.33, blue: 0.26))
                    .cornerRadius(6)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.89, green: 0.75, blue: 0.47))
                    Text("قرآن أندرويد")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.89, green: 0.75, blue: 0.47))
                }
            }

            Spacer()

            Text(entry.text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: .infinity)

            Spacer()

            HStack {
                Text(entry.source)
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.55, green: 0.69, blue: 0.63))
                    .lineLimit(1)

                Spacer()

                Text("يتغير كل ١٠ دقائق")
                    .font(.system(size: 9))
                    .foregroundColor(Color(red: 0.4, green: 0.55, blue: 0.5))
            }
        }
        .padding(14)
        .background(emeraldBackground)
    }

    // Large Widget (4x4)
    var largeView: some View {
        VStack(alignment: .center, spacing: 12) {
            HStack {
                Text(entry.category)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.36, green: 0.86, blue: 0.71))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.16, green: 0.33, blue: 0.26))
                    .cornerRadius(8)

                Spacer()

                Text("ذكر واستغفار")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.89, green: 0.75, blue: 0.47))
            }

            Spacer()

            VStack(spacing: 8) {
                Text(entry.text)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(6)
                    .padding(.horizontal, 8)

                Text(entry.source)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.65, green: 0.79, blue: 0.73))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Color(red: 0.08, green: 0.17, blue: 0.14))
            .cornerRadius(14)

            Spacer()

            HStack {
                Text("تطبيق القرآن الكريم")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.36, green: 0.86, blue: 0.71))
                Spacer()
                Text("تجدد آلي كل ١٠ د")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.55, green: 0.69, blue: 0.63))
            }
        }
        .padding(16)
        .background(emeraldBackground)
    }

    // Lock Screen Rectangular
    var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("📿 ذكر وتذكير")
                .font(.system(size: 10, weight: .bold))
            Text(entry.text)
                .font(.system(size: 11))
                .lineLimit(2)
        }
    }

    // Lock Screen Inline
    var accessoryInlineView: some View {
        Text("📿 \(entry.text)")
    }

    // Lock Screen Circular
    var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 16))
        }
    }

    var emeraldBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.15, blue: 0.11),
                Color(red: 0.04, green: 0.09, blue: 0.07)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Azkar Widget Definition
struct MyHomeWidget: Widget {
    let kind: String = "MyHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AzkarTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                AzkarWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                AzkarWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("أذكار وتسابيح")
        .description("يعرض ذكرًا أو دعاءً قرآنيًا ونبويًا يتجدد تلقائيًا كل ١٠ دقائق طوال اليوم دون الحاجة لفتح التطبيق.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}

// MARK: - Prayer Times Widget for iOS
struct PrayerEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: String
    let cityName: String
}

struct PrayerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: Date(), nextPrayerName: "الظهر", nextPrayerTime: "12:00 م", cityName: "القاهرة")
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(loadSharedPrayer())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let entry = loadSharedPrayer()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadSharedPrayer() -> PrayerEntry {
        let defaults = UserDefaults(suiteName: "group.com.homeScreenApp")
        let name = defaults?.string(forKey: "next_prayer_name") ?? "الصلاة"
        let time = defaults?.string(forKey: "next_prayer_time") ?? "--:--"
        let city = defaults?.string(forKey: "prayer_city") ?? "القاهرة"
        return PrayerEntry(date: Date(), nextPrayerName: name, nextPrayerTime: time, cityName: city)
    }
}

struct PrayerWidgetEntryView: View {
    var entry: PrayerTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Text(entry.cityName)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.55, green: 0.69, blue: 0.63))
                Spacer()
                Text("مواقيت الصلاة 🕌")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.89, green: 0.75, blue: 0.47))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("الصلاة القادمة")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.65, green: 0.79, blue: 0.73))
                Text(entry.nextPrayerName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text(entry.nextPrayerTime)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.36, green: 0.86, blue: 0.71))
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.15, blue: 0.11), Color(red: 0.04, green: 0.09, blue: 0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                PrayerWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PrayerWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("مواقيت الصلاة")
        .description("عرض الصلاة القادمة ووقتها مع العد التنازلي.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
