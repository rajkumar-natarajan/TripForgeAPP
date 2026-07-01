import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: TripStore
    @State private var showNewTrip = false

    var body: some View {
        NavigationStack {
            DashboardView(showNewTrip: $showNewTrip)
        }
        .sheet(isPresented: $showNewTrip) {
            NewTripView()
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var store: TripStore
    @Binding var showNewTrip: Bool
    @State private var template: TripTemplate?

    var body: some View {
        ZStack {
            AuroraBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if store.trips.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(store.trips) { trip in
                                NavigationLink {
                                    TripDetailView(tripID: trip.id)
                                } label: {
                                    TripCard(trip: trip)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) { store.delete(trip) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }

                    templatesSection
                }
                .padding(20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { BrandLogo() }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewTrip = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Brand.teal)
                }
                .accessibilityIdentifier("newTripButton")
                .accessibilityLabel("New trip")
            }
        }
        .sheet(item: $template) { tpl in
            NewTripView(template: tpl)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("My Trips").font(.system(size: 30, weight: .bold))
            Text("Your planned adventures, saved on this device.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Brand.brandGradient.opacity(0.2)).frame(width: 60, height: 60)
                Image(systemName: "sparkles").font(.title).foregroundStyle(Brand.tealLight)
            }
            Text("No trips yet").font(.headline)
            Text("Start with a template below, or plan from scratch.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button { showNewTrip = true } label: {
                Label("Plan your first trip", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .cardStyle()
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start from a template").font(.system(size: 20, weight: .bold))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(Constants.templates) { tpl in
                    Button { template = tpl } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tpl.emoji).font(.system(size: 30))
                            Text(LocalizedStringKey(tpl.name)).font(.headline)
                            Text(LocalizedStringKey(tpl.description)).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                        .padding(14)
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct TripCard: View {
    let trip: Trip
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "mappin.circle.fill").font(.caption)
                Text(trip.destination).font(.caption.weight(.semibold))
            }
            .foregroundStyle(Brand.tealLight)

            Text(trip.title).font(.title3.weight(.semibold)).foregroundStyle(.white)
                .lineLimit(2)

            HStack(spacing: 16) {
                Label(DateUtils.rangeLabel(trip.startDate, trip.endDate), systemImage: "calendar")
                Label("\(trip.travelers)", systemImage: "person.2.fill")
            }
            .font(.caption).foregroundStyle(.secondary)

            HStack {
                Text("\(trip.days.count) days")
                    .font(.caption).padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.white.opacity(0.06)).clipShape(Capsule())
                Spacer()
                Text(Money.format(trip.budget, trip.currency))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.orange)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
