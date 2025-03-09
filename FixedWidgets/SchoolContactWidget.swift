import SwiftUI

// Kontakt-Widget für die Marienschule
struct SchoolContactWidget: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                Text("Kontakt")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Schulname
                Text("MARIENSCHULE")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                // Adresse
                ContactInfoRow(icon: "mappin.circle.fill", title: "Adresse", content: "Sieboldstraße 4a\n33611 Bielefeld")
                
                // Telefon/Fax
                ContactInfoRow(icon: "phone.fill", title: "Telefon/Fax", content: "0521 871851\n0521 8016135")
                
                // E-Mail
                ContactInfoRow(icon: "envelope.fill", title: "E-Mail", content: "kontakt@marienschule-bielefeld.de", isLink: true, linkType: .email)
                
                // Internet
                ContactInfoRow(icon: "globe", title: "Internet", content: "marienschule-bielefeld.de", isLink: true, linkType: .website)
                    .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// Hilfsstruct für Kontaktinformationen
struct ContactInfoRow: View {
    let icon: String
    let title: String
    let content: String
    var isLink: Bool = false
    var linkType: LinkType = .none
    
    enum LinkType {
        case none, email, website, phone
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if isLink {
                Button(action: {
                    openLink()
                }) {
                    Text(content)
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func openLink() {
        var urlString = ""
        
        switch linkType {
        case .email:
            urlString = "mailto:\(content)"
        case .website:
            urlString = "https://\(content)"
        case .phone:
            urlString = "tel:\(content.replacingOccurrences(of: " ", with: ""))"
        default:
            return
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
