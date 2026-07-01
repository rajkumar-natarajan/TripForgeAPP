import SwiftUI

struct TripDetailView: View {
    @EnvironmentObject var store: TripStore
    let tripID: String

    @State private var activeDay = 0
    @State private var showAddActivity = false
    @State private var shareURL: ShareURL?
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false

    private var trip: Trip? { store.trip(withID: tripID) }

    var body: some View {
        ZStack {
            AuroraBackground()
            if let trip {
                content(trip)
            } else {
                notFound
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareURL) { s in ShareSheet(items: [s.url]) }
        .alert("Calendar", isPresented: $showCalendarAlert, presenting: calendarMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { Text($0) }
    }

    private func content(_ trip: Trip) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard(trip)
                budgetBar(trip)
                dayTabs(trip)
                if trip.days.indices.contains(activeDay) {
                    dayContent(trip, trip.days[activeDay])
                }
            }
            .padding(20)
        }
    }

    // MARK: Header

    private func headerCard(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "mappin.circle.fill")
                Text(trip.destination).font(.subheadline.weight(.semibold))
            }.foregroundStyle(Brand.tealLight)

            Text(trip.title).font(.system(size: 26, weight: .bold)).foregroundStyle(.white)

            HStack(spacing: 16) {
                Label(DateUtils.rangeLabel(trip.startDate, trip.endDate), systemImage: "calendar")
                Label("\(trip.travelers)", systemImage: "person.2.fill")
                Label(Money.format(trip.budget, trip.currency), systemImage: "wallet.pass.fill")
            }
            .font(.caption).foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button { Task { await addToCalendar(trip) } } label: {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                }.buttonStyle(GhostButtonStyle())
                Button { shareURL = CalendarExport.writeICS(for: trip).map(ShareURL.init) } label: {
                    Label("Export .ics", systemImage: "square.and.arrow.up")
                }.buttonStyle(GhostButtonStyle())
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.aurora.opacity(0.4))
        .cardStyle()
    }

    // MARK: Budget

    private func budgetBar(_ trip: Trip) -> some View {
        let total = trip.totalCost
        let pct = trip.budget > 0 ? min(1.0, total / trip.budget) : 0
        let over = total > trip.budget && trip.budget > 0
        return SectionCard {
            HStack {
                Text("Estimated spend").font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Money.format(total, trip.currency)) / \(Money.format(trip.budget, trip.currency))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(over ? .red : Brand.tealLight)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(over ? AnyShapeStyle(Color.red) : AnyShapeStyle(Brand.brandGradient))
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 10)
            if over {
                Text("Over budget by \(Money.format(total - trip.budget, trip.currency)). Consider trimming a few paid activities.")
                    .font(.caption).foregroundStyle(.red)
            }
        }
    }

    // MARK: Day tabs

    private func dayTabs(_ trip: Trip) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(trip.days.enumerated()), id: \.element.id) { i, day in
                    Button { activeDay = i } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Day \(i + 1)").font(.caption2).foregroundStyle(.secondary)
                            Text("\(day.weather?.emoji ?? "") \(day.title)")
                                .font(.subheadline.weight(.semibold)).lineLimit(1)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(i == activeDay ? Brand.teal.opacity(0.15) : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(i == activeDay ? Brand.teal.opacity(0.4) : Color.white.opacity(0.1)))
                        .foregroundStyle(.white)
                    }.buttonStyle(.plain)
                    .accessibilityIdentifier("dayTab-\(i)")
                }
            }
        }
    }

    // MARK: Day content

    private func dayContent(_ trip: Trip, _ day: Day) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(DateUtils.dayLabel(day.date)).font(.title3.weight(.bold))
                    Text(day.summary).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let w = day.weather {
                    VStack(spacing: 0) {
                        Text(w.emoji).font(.title3)
                        Text("\(w.high)° / \(w.low)°").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(Array(day.activities.enumerated()), id: \.element.id) { idx, act in
                ActivityRow(
                    index: idx, activity: act, currency: trip.currency,
                    canMoveUp: idx > 0, canMoveDown: idx < day.activities.count - 1,
                    onMoveUp: { move(trip, day, idx, idx - 1) },
                    onMoveDown: { move(trip, day, idx, idx + 2) },
                    onDelete: { store.removeActivity(tripID: trip.id, dayID: day.id, activityID: act.id) }
                )
            }

            if day.activities.isEmpty {
                Text("No activities yet for this day.").font(.subheadline)
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 20).cardStyle()
            }

            Button { showAddActivity = true } label: { Label("Add activity", systemImage: "plus") }
                .buttonStyle(GhostButtonStyle())

            MapPanelView(day: day)

            packingCard(trip)

            if let prompt = trip.prompt {
                SectionCard {
                    Label("Original request", systemImage: "sparkles")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text("“\(prompt)”").font(.subheadline).italic().foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showAddActivity) {
            AddActivityView { newActivity in
                store.addActivity(tripID: trip.id, dayID: day.id, activity: newActivity)
            }
        }
    }

    private func packingCard(_ trip: Trip) -> some View {
        SectionCard {
            Label("Packing list", systemImage: "bag.fill").font(.headline)
            ForEach(trip.packingList) { item in
                Button { store.togglePacked(tripID: trip.id, itemID: item.id) } label: {
                    HStack {
                        Image(systemName: item.packed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.packed ? Brand.teal : .secondary)
                        Text(item.label)
                            .strikethrough(item.packed).foregroundStyle(item.packed ? .secondary : .primary)
                        Spacer()
                        Text(item.category).font(.caption2).foregroundStyle(.tertiary)
                    }
                }.buttonStyle(.plain)
            }
        }
    }

    private var notFound: some View {
        VStack(spacing: 12) {
            Text("Trip not found").font(.title2.weight(.bold))
            Text("It may have been deleted.").foregroundStyle(.secondary)
        }
    }

    // MARK: Actions

    private func move(_ trip: Trip, _ day: Day, _ from: Int, _ to: Int) {
        store.moveActivity(tripID: trip.id, dayID: day.id, from: IndexSet(integer: from), to: to)
    }

    private func addToCalendar(_ trip: Trip) async {
        let result = await CalendarExport.addToCalendar(trip)
        switch result {
        case .success(let count): calendarMessage = "Added \(count) events to your calendar."
        case .failure(let err): calendarMessage = err.localizedDescription
        }
        showCalendarAlert = true
    }
}

struct ShareURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

// MARK: - Activity row

struct ActivityRow: View {
    let index: Int
    let activity: Activity
    let currency: String
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
                Text(activity.type.emoji)
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(spacing: 2) {
                    Button(action: onMoveUp) { Image(systemName: "chevron.up") }
                        .disabled(!canMoveUp).foregroundStyle(canMoveUp ? Brand.tealLight : Color.secondary)
                        .accessibilityIdentifier("act-\(index)-up")
                    Button(action: onMoveDown) { Image(systemName: "chevron.down") }
                        .disabled(!canMoveDown).foregroundStyle(canMoveDown ? Brand.tealLight : Color.secondary)
                        .accessibilityIdentifier("act-\(index)-down")
                }.font(.caption)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.title).font(.subheadline.weight(.semibold))
                        .accessibilityIdentifier("actTitle-\(index)")
                    Spacer()
                    if activity.cost > 0 {
                        Text(Money.format(activity.cost, currency))
                            .font(.caption.weight(.medium)).foregroundStyle(Brand.orange)
                    }
                }
                HStack(spacing: 10) {
                    Label("\(DateUtils.time12(activity.startTime))–\(DateUtils.time12(DateUtils.addMinutes(to: activity.startTime, activity.durationMin)))", systemImage: "clock")
                    Label(activity.location, systemImage: "mappin").lineLimit(1)
                }
                .font(.caption2).foregroundStyle(.secondary)
                Text(activity.description).font(.caption).foregroundStyle(Color(hex: 0xCBD5E1))
                Button(role: .destructive, action: onDelete) {
                    Label("Remove", systemImage: "trash").font(.caption2)
                }.padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Add activity

struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (Activity) -> Void

    @State private var title = ""
    @State private var type: ActivityType = .attraction
    @State private var startTime = Date()
    @State private var durationMin = 60
    @State private var cost = 0.0
    @State private var location = ""
    @State private var description = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(ActivityType.allCases) { t in Text("\(t.emoji) \(t.label)").tag(t) }
                    }
                    TextField("Location", text: $location)
                    DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                    Stepper("Duration: \(durationMin) min", value: $durationMin, in: 15...480, step: 15)
                    TextField("Cost", value: $cost, format: .number).keyboardType(.numberPad)
                    TextField("Notes / description", text: $description, axis: .vertical)
                }
            }
            .navigationTitle("Add activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let f = DateFormatter(); f.dateFormat = "HH:mm"
                        onAdd(Activity(
                            title: title, type: type, description: description,
                            startTime: f.string(from: startTime), durationMin: durationMin,
                            cost: cost, location: location
                        ))
                        dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
