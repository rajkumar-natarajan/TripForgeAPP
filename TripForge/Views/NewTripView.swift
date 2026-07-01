import SwiftUI

struct NewTripView: View {
    @EnvironmentObject var store: TripStore
    @Environment(\.dismiss) private var dismiss

    enum Mode { case prompt, form }
    @State private var mode: Mode = .prompt
    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var createdTrip: TripRef?

    // Form state
    @State private var destination = ""
    @State private var startDate = Date().addingTimeInterval(30 * 86400)
    @State private var endDate = Date().addingTimeInterval(33 * 86400)
    @State private var travelers = 2
    @State private var budget = 2500.0
    @State private var currency = "USD"
    @State private var travelStyle: TravelStyle = .balanced
    @State private var pace: Pace = .moderate
    @State private var interests: Set<String> = []
    @State private var dietary: Set<String> = []

    var template: TripTemplate?

    private let examples = [
        "5 days in Tokyo in mid July with my wife, love food and anime, budget $3000",
        "A relaxed long weekend in Paris for 2, art and cafes, €1200",
        "7-day family trip to Bali, beaches and nature"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        picker
                        if mode == .prompt { promptCard } else { formCard }
                        generateButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Plan a new trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(item: $createdTrip) { ref in
                TripDetailView(tripID: ref.id)
            }
        }
        .onAppear(perform: applyTemplate)
    }

    private var picker: some View {
        Picker("", selection: $mode) {
            Text("Describe").tag(Mode.prompt)
            Text("Smart form").tag(Mode.form)
        }
        .pickerStyle(.segmented)
    }

    private var promptCard: some View {
        SectionCard {
            Text("Tell us about your trip").font(.subheadline.weight(.medium))
            ZStack(alignment: .topLeading) {
                if prompt.isEmpty {
                    Text("e.g. 5 days in Tokyo in mid July with my wife, love food and anime, budget $3000")
                        .foregroundStyle(.tertiary).padding(8)
                }
                TextEditor(text: $prompt)
                    .frame(minHeight: 110)
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .accessibilityIdentifier("promptEditor")
            }
            .background(Brand.ink800.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Try an example").font(.caption).foregroundStyle(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(examples, id: \.self) { ex in
                    Button { prompt = ex } label: {
                        Chip(label: String(ex.prefix(28)) + "…", selected: false)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var formCard: some View {
        SectionCard {
            field("Destination") {
                TextField("Tokyo, Paris, Bali…", text: $destination).textFieldStyle(.roundedBorder)
            }
            HStack {
                field("Start") { DatePicker("", selection: $startDate, displayedComponents: .date).labelsHidden() }
                field("End") { DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date).labelsHidden() }
            }
            HStack {
                field("Travelers") { Stepper("\(travelers)", value: $travelers, in: 1...20) }
            }
            HStack {
                field("Budget") {
                    TextField("Budget", value: $budget, format: .number).textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                }
                field("Currency") {
                    Picker("", selection: $currency) {
                        ForEach(Constants.currencies, id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(.menu).tint(Brand.tealLight)
                }
            }
            field("Travel style") {
                FlowLayout(spacing: 8) {
                    ForEach(TravelStyle.allCases) { s in
                        Button { travelStyle = s } label: { Chip(label: s.label, selected: travelStyle == s) }
                            .buttonStyle(.plain)
                    }
                }
            }
            field("Pace") {
                HStack(spacing: 8) {
                    ForEach(Pace.allCases) { p in
                        Button { pace = p } label: {
                            VStack(spacing: 2) {
                                Text(p.label).font(.subheadline.weight(.semibold))
                                Text(p.hint).font(.caption2).opacity(0.7)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(pace == p ? Brand.teal.opacity(0.15) : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(pace == p ? Brand.teal.opacity(0.4) : Color.white.opacity(0.1)))
                            .foregroundStyle(pace == p ? Brand.tealLight : Color(hex: 0xCBD5E1))
                        }.buttonStyle(.plain)
                    }
                }
            }
            field("Interests") {
                FlowLayout(spacing: 8) {
                    ForEach(Constants.interestOptions, id: \.self) { i in
                        Button { toggle(&interests, i) } label: { Chip(label: i, selected: interests.contains(i)) }
                            .buttonStyle(.plain)
                    }
                }
            }
            field("Dietary needs") {
                FlowLayout(spacing: 8) {
                    ForEach(Constants.dietaryOptions, id: \.self) { d in
                        Button { toggle(&dietary, d) } label: { Chip(label: d, selected: dietary.contains(d)) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var generateButton: some View {
        VStack(spacing: 8) {
            Button(action: generate) {
                if isGenerating {
                    HStack { ProgressView().tint(.white); Text("Designing your itinerary…") }
                } else {
                    Label("Generate itinerary", systemImage: "wand.and.stars")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSubmit || isGenerating)

            Text("Built-in offline planner — always free, no keys needed.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var canSubmit: Bool {
        mode == .prompt ? prompt.trimmingCharacters(in: .whitespaces).count > 8
                        : destination.trimmingCharacters(in: .whitespaces).count > 1
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggle(_ set: inout Set<String>, _ v: String) {
        if set.contains(v) { set.remove(v) } else { set.insert(v) }
    }

    private func applyTemplate() {
        guard let tpl = template else { return }
        mode = .form
        travelStyle = tpl.travelStyle
        pace = tpl.pace
        interests = Set(tpl.interests.filter { Constants.interestOptions.contains($0) })
    }

    private func generate() {
        isGenerating = true
        let input: PlannerInput
        var promptToSave: String? = nil
        if mode == .prompt {
            input = TripStore.coerceInput(prompt: prompt)
            promptToSave = prompt
        } else {
            input = TripStore.coerceInput(
                prompt: nil,
                destination: destination,
                startDate: DateUtils.iso.string(from: startDate),
                endDate: DateUtils.iso.string(from: endDate),
                travelers: travelers,
                budget: budget,
                currency: currency,
                interests: Array(interests),
                pace: pace,
                travelStyle: travelStyle,
                dietary: Array(dietary)
            )
        }
        // Small delay so the loading state is visible and feels responsive.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let trip = store.createTrip(input: input, prompt: promptToSave)
            isGenerating = false
            createdTrip = TripRef(id: trip.id)
        }
    }
}

struct TripRef: Identifiable, Hashable {
    let id: String
}
