import SwiftUI
import MapKit

// MARK: - Search Suggestions Dropdown

struct SearchSuggestions: View {
    let results: [MKLocalSearchCompletion]
    let onSelect: (MKLocalSearchCompletion, String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(results, id: \.self) { result in
                    Button {
                        onSelect(result, result.title)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title).foregroundStyle(.red)
                            Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal, 20)
        .padding(.top, 5)
        .frame(maxHeight: 200)
    }
}
