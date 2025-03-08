import SwiftUI

struct FloatingMenuBar: View {
    @Binding var currentPage: Page
    
    enum Page {
        case home
        case calendar
        case tasks
        case studentID
        case account
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                MenuButton(icon: "house.fill", 
                          isSelected: currentPage == .home,
                          action: { currentPage = .home })
                Spacer()
                MenuButton(icon: "calendar", 
                          isSelected: currentPage == .calendar,
                          action: { currentPage = .calendar })
                Spacer()
                MenuButton(icon: "checkmark.circle",
                          isSelected: currentPage == .tasks,
                          action: { currentPage = .tasks })
                Spacer()
                MenuButton(icon: "book.fill",
                          isSelected: currentPage == .studentID,
                          action: { currentPage = .studentID })
                Spacer()
                MenuButton(icon: "checkmark.circle",
                           isSelected: currentPage == .account,
                           action: { currentPage = .account })
            }
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadius(25)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
    }
}

struct MenuButton: View {
    var icon: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundColor(isSelected ? .blue : .white)
        }
    }
}
