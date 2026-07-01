import Foundation

// Offline, deterministic itinerary generator — the native Swift port of the web
// app's planner. Works with zero network / API keys.

struct POI {
    let title: String
    let type: ActivityType
    let description: String
    let durationMin: Int
    let costPP: Double
    let location: String
    let coords: GeoPoint
    let tags: [String]
}

struct CityData {
    let coords: GeoPoint
    let currency: String
    let pois: [POI]
}

enum Planner {

    // MARK: Curated city bank

    static let cities: [String: CityData] = [
        "tokyo": CityData(coords: GeoPoint(lat: 35.6762, lng: 139.6503), currency: "JPY", pois: [
            POI(title: "Senso-ji Temple", type: .attraction, description: "Tokyo's oldest temple in historic Asakusa, framed by the Kaminarimon gate.", durationMin: 90, costPP: 0, location: "Asakusa, Tokyo", coords: GeoPoint(lat: 35.7148, lng: 139.7967), tags: ["history", "architecture", "culture"]),
            POI(title: "teamLab Planets", type: .attraction, description: "Immersive digital art museum you walk through barefoot.", durationMin: 120, costPP: 25, location: "Toyosu, Tokyo", coords: GeoPoint(lat: 35.6494, lng: 139.7898), tags: ["art", "photography"]),
            POI(title: "Tsukiji Outer Market", type: .food, description: "Legendary street-food alleys — fresh sushi, tamagoyaki, and more.", durationMin: 90, costPP: 20, location: "Tsukiji, Tokyo", coords: GeoPoint(lat: 35.6655, lng: 139.7707), tags: ["food", "markets"]),
            POI(title: "Akihabara Electric Town", type: .shopping, description: "Neon paradise of anime, retro games, and gadget shops.", durationMin: 120, costPP: 15, location: "Akihabara, Tokyo", coords: GeoPoint(lat: 35.7022, lng: 139.7745), tags: ["anime", "shopping"]),
            POI(title: "Shibuya Crossing & Sky", type: .attraction, description: "The world's busiest crossing plus a rooftop view from Shibuya Sky.", durationMin: 90, costPP: 18, location: "Shibuya, Tokyo", coords: GeoPoint(lat: 35.6595, lng: 139.7005), tags: ["views", "photography"]),
            POI(title: "Ichiran Ramen", type: .food, description: "Rich tonkotsu ramen in focus-booth seating — a Tokyo rite of passage.", durationMin: 60, costPP: 12, location: "Shibuya, Tokyo", coords: GeoPoint(lat: 35.6614, lng: 139.7006), tags: ["food"]),
            POI(title: "Meiji Shrine", type: .nature, description: "Serene forest shrine dedicated to Emperor Meiji near Harajuku.", durationMin: 75, costPP: 0, location: "Shibuya, Tokyo", coords: GeoPoint(lat: 35.6764, lng: 139.6993), tags: ["nature", "history"]),
            POI(title: "Ghibli Museum", type: .hiddenGem, description: "Whimsical museum celebrating Studio Ghibli (book ahead!).", durationMin: 120, costPP: 10, location: "Mitaka, Tokyo", coords: GeoPoint(lat: 35.6962, lng: 139.5704), tags: ["anime", "art"]),
            POI(title: "Golden Gai", type: .nightlife, description: "Tiny atmospheric bars packed into six narrow lanes in Shinjuku.", durationMin: 120, costPP: 30, location: "Shinjuku, Tokyo", coords: GeoPoint(lat: 35.6938, lng: 139.7048), tags: ["nightlife"]),
            POI(title: "Blue Bottle Kiyosumi", type: .cafe, description: "Flagship specialty coffee roastery in a converted warehouse.", durationMin: 45, costPP: 8, location: "Kiyosumi, Tokyo", coords: GeoPoint(lat: 35.6810, lng: 139.8000), tags: ["coffee", "cafes"])
        ]),
        "paris": CityData(coords: GeoPoint(lat: 48.8566, lng: 2.3522), currency: "EUR", pois: [
            POI(title: "Eiffel Tower", type: .attraction, description: "Iconic iron landmark — book a summit ticket for sunset.", durationMin: 120, costPP: 29, location: "Champ de Mars, Paris", coords: GeoPoint(lat: 48.8584, lng: 2.2945), tags: ["views", "architecture"]),
            POI(title: "Louvre Museum", type: .attraction, description: "The world's most-visited museum, home to the Mona Lisa.", durationMin: 180, costPP: 22, location: "Rue de Rivoli, Paris", coords: GeoPoint(lat: 48.8606, lng: 2.3376), tags: ["art", "history", "museums"]),
            POI(title: "Le Marais Food Walk", type: .food, description: "Falafel, fromageries and patisseries through the historic Marais.", durationMin: 120, costPP: 25, location: "Le Marais, Paris", coords: GeoPoint(lat: 48.8590, lng: 2.3620), tags: ["food", "markets"]),
            POI(title: "Montmartre & Sacré-Cœur", type: .attraction, description: "Hilltop artists' quarter with sweeping city views.", durationMin: 120, costPP: 0, location: "Montmartre, Paris", coords: GeoPoint(lat: 48.8867, lng: 2.3431), tags: ["art", "views", "history"]),
            POI(title: "Musée d'Orsay", type: .attraction, description: "Impressionist masterpieces in a beautiful former railway station.", durationMin: 120, costPP: 16, location: "Rive Gauche, Paris", coords: GeoPoint(lat: 48.8600, lng: 2.3266), tags: ["art", "museums"]),
            POI(title: "Seine River Cruise", type: .attraction, description: "Glide past illuminated monuments after dark.", durationMin: 75, costPP: 17, location: "Port de la Bourdonnais, Paris", coords: GeoPoint(lat: 48.8608, lng: 2.2936), tags: ["views", "romance"]),
            POI(title: "Café de Flore", type: .cafe, description: "Storied Left Bank café once frequented by Sartre and de Beauvoir.", durationMin: 60, costPP: 12, location: "Saint-Germain, Paris", coords: GeoPoint(lat: 48.8542, lng: 2.3327), tags: ["coffee", "cafes"]),
            POI(title: "Canal Saint-Martin", type: .hiddenGem, description: "Leafy canal loved by locals for picnics and indie boutiques.", durationMin: 90, costPP: 5, location: "10th arr., Paris", coords: GeoPoint(lat: 48.8709, lng: 2.3674), tags: ["hidden gems", "nature"])
        ]),
        "new york": CityData(coords: GeoPoint(lat: 40.7128, lng: -74.006), currency: "USD", pois: [
            POI(title: "Central Park", type: .nature, description: "843 acres of green — rent a bike or row a boat on the lake.", durationMin: 120, costPP: 0, location: "Manhattan, NYC", coords: GeoPoint(lat: 40.7829, lng: -73.9654), tags: ["nature", "family"]),
            POI(title: "The Met", type: .attraction, description: "Encyclopedic art museum on Museum Mile.", durationMin: 150, costPP: 30, location: "1000 5th Ave, NYC", coords: GeoPoint(lat: 40.7794, lng: -73.9632), tags: ["art", "museums"]),
            POI(title: "Top of the Rock", type: .attraction, description: "Best skyline view in the city — includes the Empire State.", durationMin: 75, costPP: 40, location: "Rockefeller Center, NYC", coords: GeoPoint(lat: 40.7593, lng: -73.9794), tags: ["views", "photography"]),
            POI(title: "Chelsea Market & High Line", type: .food, description: "Food hall feast then a stroll on the elevated park.", durationMin: 120, costPP: 25, location: "Chelsea, NYC", coords: GeoPoint(lat: 40.7425, lng: -74.006), tags: ["food", "markets"]),
            POI(title: "Brooklyn Bridge Walk", type: .attraction, description: "Walk from Manhattan to DUMBO for postcard views.", durationMin: 90, costPP: 0, location: "Brooklyn Bridge, NYC", coords: GeoPoint(lat: 40.7061, lng: -73.9969), tags: ["views", "photography"]),
            POI(title: "Broadway Show", type: .nightlife, description: "Catch a world-class musical in the Theater District.", durationMin: 150, costPP: 90, location: "Times Square, NYC", coords: GeoPoint(lat: 40.759, lng: -73.9845), tags: ["music", "nightlife"]),
            POI(title: "Katz's Delicatessen", type: .food, description: "Towering pastrami on rye since 1888.", durationMin: 60, costPP: 28, location: "Lower East Side, NYC", coords: GeoPoint(lat: 40.7223, lng: -73.9874), tags: ["food"])
        ]),
        "rome": CityData(coords: GeoPoint(lat: 41.9028, lng: 12.4964), currency: "EUR", pois: [
            POI(title: "Colosseum", type: .attraction, description: "The mighty amphitheater of ancient Rome — skip-the-line advised.", durationMin: 120, costPP: 18, location: "Piazza del Colosseo, Rome", coords: GeoPoint(lat: 41.8902, lng: 12.4922), tags: ["history", "architecture"]),
            POI(title: "Vatican Museums & Sistine Chapel", type: .attraction, description: "Michelangelo's ceiling and endless galleries.", durationMin: 180, costPP: 24, location: "Vatican City", coords: GeoPoint(lat: 41.9065, lng: 12.4536), tags: ["art", "history"]),
            POI(title: "Trastevere Food Crawl", type: .food, description: "Cacio e pepe, supplì and gelato through cobbled lanes.", durationMin: 120, costPP: 30, location: "Trastevere, Rome", coords: GeoPoint(lat: 41.889, lng: 12.4697), tags: ["food"]),
            POI(title: "Pantheon", type: .attraction, description: "Astonishing 2,000-year-old dome, free to enter.", durationMin: 45, costPP: 0, location: "Piazza della Rotonda, Rome", coords: GeoPoint(lat: 41.8986, lng: 12.4769), tags: ["history", "architecture"]),
            POI(title: "Trevi Fountain", type: .attraction, description: "Toss a coin at the Baroque masterpiece.", durationMin: 30, costPP: 0, location: "Trevi, Rome", coords: GeoPoint(lat: 41.9009, lng: 12.4833), tags: ["photography"]),
            POI(title: "Sant'Eustachio Il Caffè", type: .cafe, description: "Rome's most famous espresso, pulled since 1938.", durationMin: 40, costPP: 6, location: "Sant'Eustachio, Rome", coords: GeoPoint(lat: 41.8981, lng: 12.4747), tags: ["coffee"])
        ]),
        "barcelona": CityData(coords: GeoPoint(lat: 41.3874, lng: 2.1686), currency: "EUR", pois: [
            POI(title: "Sagrada Família", type: .attraction, description: "Gaudí's breathtaking unfinished basilica.", durationMin: 120, costPP: 26, location: "Eixample, Barcelona", coords: GeoPoint(lat: 41.4036, lng: 2.1744), tags: ["architecture", "art"]),
            POI(title: "Park Güell", type: .attraction, description: "Whimsical mosaic park with city and sea views.", durationMin: 120, costPP: 10, location: "Gràcia, Barcelona", coords: GeoPoint(lat: 41.4145, lng: 2.1527), tags: ["architecture", "views", "nature"]),
            POI(title: "La Boqueria Market", type: .food, description: "Riot of colour and tapas just off La Rambla.", durationMin: 90, costPP: 20, location: "La Rambla, Barcelona", coords: GeoPoint(lat: 41.3818, lng: 2.1717), tags: ["food", "markets"]),
            POI(title: "Gothic Quarter Walk", type: .attraction, description: "Medieval alleys, hidden squares and Roman ruins.", durationMin: 90, costPP: 0, location: "Ciutat Vella, Barcelona", coords: GeoPoint(lat: 41.3833, lng: 2.1777), tags: ["history", "architecture"]),
            POI(title: "Barceloneta Beach", type: .nature, description: "City beach for a swim and a seafood paella.", durationMin: 150, costPP: 25, location: "Barceloneta, Barcelona", coords: GeoPoint(lat: 41.3785, lng: 2.1925), tags: ["beaches", "food"])
        ]),
        "bali": CityData(coords: GeoPoint(lat: -8.4095, lng: 115.1889), currency: "IDR", pois: [
            POI(title: "Tegallalang Rice Terraces", type: .nature, description: "Emerald stepped paddies north of Ubud.", durationMin: 90, costPP: 3, location: "Tegallalang, Bali", coords: GeoPoint(lat: -8.4312, lng: 115.2777), tags: ["nature", "photography"]),
            POI(title: "Uluwatu Temple & Kecak", type: .attraction, description: "Clifftop sea temple with a fire-dance at sunset.", durationMin: 150, costPP: 12, location: "Uluwatu, Bali", coords: GeoPoint(lat: -8.8291, lng: 115.0849), tags: ["culture", "views"]),
            POI(title: "Ubud Monkey Forest", type: .nature, description: "Sacred sanctuary with mischievous macaques.", durationMin: 75, costPP: 6, location: "Ubud, Bali", coords: GeoPoint(lat: -8.5188, lng: 115.2582), tags: ["nature", "family"]),
            POI(title: "Warung Babi Guling", type: .food, description: "Balinese suckling pig — the island's signature feast.", durationMin: 60, costPP: 8, location: "Ubud, Bali", coords: GeoPoint(lat: -8.5069, lng: 115.2625), tags: ["food"]),
            POI(title: "Seminyak Beach Club", type: .nightlife, description: "Sunset cocktails with your toes in the sand.", durationMin: 150, costPP: 30, location: "Seminyak, Bali", coords: GeoPoint(lat: -8.6913, lng: 115.1571), tags: ["beaches", "nightlife"])
        ])
    ]

    static let aliases: [String: String] = [
        "nyc": "new york", "new york city": "new york", "manhattan": "new york"
    ]

    static let weather: [Weather] = [
        Weather(high: 27, low: 18, condition: "Sunny", emoji: "☀️"),
        Weather(high: 24, low: 16, condition: "Partly Cloudy", emoji: "⛅"),
        Weather(high: 26, low: 17, condition: "Clear", emoji: "🌤️"),
        Weather(high: 21, low: 15, condition: "Light Rain", emoji: "🌦️")
    ]

    static let dayThemes = [
        "Arrival & First Impressions", "Icons & Highlights", "Culture & Cuisine",
        "Hidden Gems & Local Life", "Nature & Views", "Markets & Neighborhoods", "Relax & Farewell"
    ]

    // MARK: Lookup

    static func normalizeCity(_ destination: String) -> String? {
        let key = destination.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for city in cities.keys where key.contains(city) { return city }
        if let alias = aliases[key] { return alias }
        return nil
    }

    static func genericCity(_ destination: String) -> CityData {
        let name = destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Your Destination" : destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = GeoPoint(lat: 20, lng: 0)
        func t(_ dx: Double, _ dy: Double) -> GeoPoint { GeoPoint(lat: base.lat + dx, lng: base.lng + dy) }
        let pois: [POI] = [
            POI(title: "\(name) Old Town", type: .attraction, description: "Wander the historic heart of \(name) on foot.", durationMin: 120, costPP: 0, location: "Old Town, \(name)", coords: t(0.01, 0.01), tags: ["history", "architecture"]),
            POI(title: "\(name) Central Market", type: .food, description: "Sample local specialties and street food at the main market.", durationMin: 90, costPP: 15, location: "Central Market, \(name)", coords: t(0.02, -0.01), tags: ["food", "markets"]),
            POI(title: "\(name) National Museum", type: .attraction, description: "The region's flagship art and history collection.", durationMin: 120, costPP: 12, location: "Museum District, \(name)", coords: t(-0.01, 0.02), tags: ["art", "museums", "history"]),
            POI(title: "\(name) Viewpoint", type: .attraction, description: "The best panorama over \(name) — bring a camera.", durationMin: 75, costPP: 8, location: "Hilltop, \(name)", coords: t(0.03, 0.02), tags: ["views", "photography"]),
            POI(title: "Riverside Park", type: .nature, description: "Green space perfect for a relaxed stroll or picnic.", durationMin: 90, costPP: 0, location: "Riverside, \(name)", coords: t(-0.02, -0.02), tags: ["nature", "family"]),
            POI(title: "\(name) Signature Dinner", type: .food, description: "A celebrated local restaurant for an unforgettable meal.", durationMin: 90, costPP: 35, location: "Downtown, \(name)", coords: t(0.0, 0.03), tags: ["food"]),
            POI(title: "Specialty Coffee Roaster", type: .cafe, description: "Third-wave coffee and pastries loved by locals.", durationMin: 45, costPP: 6, location: "Arts Quarter, \(name)", coords: t(0.015, -0.015), tags: ["coffee", "cafes"]),
            POI(title: "Hidden Courtyard Bar", type: .nightlife, description: "A tucked-away spot for craft cocktails after dark.", durationMin: 120, costPP: 25, location: "Old Town, \(name)", coords: t(0.005, 0.005), tags: ["nightlife"]),
            POI(title: "Artisan Boutiques", type: .shopping, description: "Independent shops for local design and souvenirs.", durationMin: 90, costPP: 20, location: "Design District, \(name)", coords: t(-0.015, 0.01), tags: ["shopping"])
        ]
        return CityData(coords: base, currency: "USD", pois: pois)
    }

    static func score(_ poi: POI, _ interests: [String]) -> Int {
        let lower = interests.map { $0.lowercased() }
        var s = 1
        for tag in poi.tags where lower.contains(where: { tag.contains($0) || $0.contains(tag) }) { s += 3 }
        if poi.type == .food && lower.contains("food") { s += 2 }
        return s
    }

    static func titleCase(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    // MARK: Generate

    static func generate(_ input: PlannerInput) -> Trip {
        let cityKey = normalizeCity(input.destination)
        let city = cityKey.flatMap { cities[$0] } ?? genericCity(input.destination)
        let numDays = DateUtils.daysBetween(input.startDate, input.endDate)
        let perDay = input.pace.activitiesPerDay

        let ranked = city.pois.sorted { score($0, input.interests) > score($1, input.interests) }
        var pool: [POI] = []
        var i = 0
        while pool.count < numDays * perDay {
            pool.append(ranked[i % ranked.count]); i += 1
        }

        var days: [Day] = []
        var poolIdx = 0
        for d in 0..<numDays {
            let date = DateUtils.addDays(input.startDate, d)
            let dayPois = Array(pool[poolIdx..<min(poolIdx + perDay, pool.count)])
            poolIdx += perDay

            var clock = "09:00"
            var activities: [Activity] = []
            for (idx, poi) in dayPois.enumerated() {
                let startTime = clock
                clock = DateUtils.addMinutes(to: clock, poi.durationMin + (idx < dayPois.count - 1 ? 45 : 0))
                activities.append(Activity(
                    title: poi.title, type: poi.type, description: poi.description,
                    startTime: startTime, durationMin: poi.durationMin,
                    cost: (poi.costPP * Double(input.travelers)).rounded(),
                    location: poi.location, coords: poi.coords
                ))
            }

            let uniqueTypes = Array(Set(dayPois.map { $0.type.label })).prefix(3).joined(separator: ", ")
            days.append(Day(
                date: date,
                title: d < dayThemes.count ? dayThemes[d] : "Day \(d + 1) Explorations",
                summary: "A \(input.pace.rawValue) day mixing \(uniqueTypes) around \(input.destination).",
                weather: weather[d % weather.count],
                activities: activities
            ))
        }

        let dest = titleCase(input.destination)
        return Trip(
            title: "\(numDays) Days in \(dest)",
            destination: dest,
            destinationCoords: city.coords,
            startDate: input.startDate,
            endDate: input.endDate,
            travelers: input.travelers,
            budget: input.budget,
            currency: input.currency.isEmpty ? city.currency : input.currency,
            travelStyle: input.travelStyle,
            pace: input.pace,
            interests: input.interests,
            dietary: input.dietary,
            prompt: nil,
            days: days,
            participants: [Participant(name: "You", role: "owner")],
            packingList: packingList(input)
        )
    }

    static func packingList(_ input: PlannerInput) -> [PackingItem] {
        var items: [PackingItem] = [
            PackingItem(label: "Passport / ID", category: "Essentials"),
            PackingItem(label: "Phone + charger", category: "Essentials"),
            PackingItem(label: "Travel adapter", category: "Essentials"),
            PackingItem(label: "Credit/debit cards + some cash", category: "Essentials"),
            PackingItem(label: "Comfortable walking shoes", category: "Clothing"),
            PackingItem(label: "Reusable water bottle", category: "Essentials"),
            PackingItem(label: "Day backpack", category: "Gear"),
            PackingItem(label: "Sunscreen + sunglasses", category: "Health"),
            PackingItem(label: "Basic first-aid + medications", category: "Health")
        ]
        let lower = input.interests.map { $0.lowercased() }
        if lower.contains("hiking") || lower.contains("nature") {
            items.append(PackingItem(label: "Hiking shoes", category: "Gear"))
            items.append(PackingItem(label: "Rain jacket", category: "Clothing"))
        }
        if lower.contains("beaches") {
            items.append(PackingItem(label: "Swimwear", category: "Clothing"))
            items.append(PackingItem(label: "Beach towel", category: "Gear"))
        }
        if lower.contains("photography") {
            items.append(PackingItem(label: "Camera + spare batteries", category: "Gear"))
        }
        if input.travelStyle == .luxury {
            items.append(PackingItem(label: "Smart outfit for fine dining", category: "Clothing"))
        }
        return items
    }
}
