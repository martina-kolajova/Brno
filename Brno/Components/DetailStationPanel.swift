struct DetailStationPanel: View {
    let station: KontejnerStation
    var onNavigate: () -> Void
    var onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text(station.ulice)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Stanoviště kontejnerů")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
            
            Divider()
            
            Text("Na stanovišti najdete:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            // Seznam ikon komodit, které tam jsou
            HStack {
                ForEach(station.komodity, id: \.self) { kom in
                    // Tady najdeme ikonu podle názvu z tvého filtru
                    if let filter = KomoditaFilter.allCases.first(where: { $0.rawValue == kom }) {
                        VStack {
                            Image(systemName: filter.iconName)
                                .frame(width: 40, height: 40)
                                .background(filter.color.opacity(0.2))
                                .foregroundStyle(filter.color)
                                .clipShape(Circle())
                            Text(filter.displayName)
                                .font(.system(size: 9))
                        }
                    }
                }
            }
            
            Button(action: onNavigate) {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Navigovat")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(15)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(radius: 10)
        .padding()
    }
}