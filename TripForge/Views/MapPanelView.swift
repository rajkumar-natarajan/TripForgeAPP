import SwiftUI
import MapKit

struct MapPanelView: View {
    let day: Day

    private var stops: [Activity] { day.activities.filter { $0.coords != nil } }

    private var region: MKCoordinateRegion {
        let coords = stops.compactMap { $0.coords }
        guard !coords.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                                      span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40))
        }
        let lats = coords.map { $0.lat }, lngs = coords.map { $0.lng }
        let center = CLLocationCoordinate2D(latitude: (lats.min()! + lats.max()!) / 2,
                                            longitude: (lngs.min()! + lngs.max()!) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.02, (lats.max()! - lats.min()!) * 1.5),
            longitudeDelta: max(0.02, (lngs.max()! - lngs.min()!) * 1.5))
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .region(region)) {
                ForEach(Array(stops.enumerated()), id: \.element.id) { idx, act in
                    if let c = act.coords {
                        Annotation(act.title, coordinate: CLLocationCoordinate2D(latitude: c.lat, longitude: c.lng)) {
                            ZStack {
                                Circle().fill(Brand.brandGradient).frame(width: 28, height: 28)
                                    .shadow(radius: 3)
                                Text("\(idx + 1)").font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                if stops.count >= 2 {
                    MapPolyline(coordinates: stops.compactMap {
                        $0.coords.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
                    })
                    .stroke(Brand.orange.opacity(0.8), lineWidth: 3)
                }
            }
            .frame(height: 240)

            Button {
                openRouteInMaps()
            } label: {
                Label("Open route in Maps", systemImage: "map.fill")
            }
            .buttonStyle(GhostButtonStyle())
            .padding(12)
        }
        .cardStyle()
    }

    private func openRouteInMaps() {
        let placemarks = stops.compactMap { act -> MKMapItem? in
            guard let c = act.coords else { return nil }
            let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: c.lat, longitude: c.lng)))
            item.name = act.title
            return item
        }
        guard !placemarks.isEmpty else { return }
        MKMapItem.openMaps(with: placemarks, launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
