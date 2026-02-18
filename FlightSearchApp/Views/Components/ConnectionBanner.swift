import SwiftUI

struct ConnectionBanner: View {
    var body: some View {
        HStack {
            Text(LocalizationService.shared.localizedString("no_internet_connection"))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(Color.red)
        .foregroundColor(.white)
    }
}

