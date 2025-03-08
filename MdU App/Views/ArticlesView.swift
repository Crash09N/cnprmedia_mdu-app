import SwiftUI

struct ArticlesView: View {
    @Binding var currentPage: Page
    @State private var articles: [WordPressArticle] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var selectedArticle: WordPressArticle? = nil
    @State private var usingBackend = true
    @State private var searchText = ""
    @State private var showSourceInfo = false
    @State private var refreshing = false
    @State private var scrollOffset: CGFloat = 0
    @State private var serverStatus: ServerStatus? = nil
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredArticles: [WordPressArticle] {
        if searchText.isEmpty {
            return articles
        } else {
            return articles.filter { article in
                article.title.plainText.lowercased().contains(searchText.lowercased()) ||
                article.excerpt.plainText.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(colorScheme == .dark ? UIColor.systemBackground : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0))
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Modern header with blur effect
                ZStack {
                    // Blur background
                    BlurView(style: colorScheme == .dark ? .dark : .light)
                        .edgesIgnoringSafeArea(.top)
                    
                    VStack(spacing: 12) {
                        // Status bar spacer
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 44)
                        
                        HStack {
                            Button(action: { 
                                withAnimation(.spring()) {
                                    currentPage = .home 
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                            }
                            
                            Spacer()
                            
                            Text("Neuigkeiten")
                                .font(.system(size: 22, weight: .bold))
                                .opacity(1.0 - min(1.0, scrollOffset / 30))
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                Button(action: {
                                    if let url = URL(string: "https://marienschule-bielefeld.de/") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .padding(10)
                                        .background(
                                            Circle()
                                                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                }
                                
                                Button(action: { 
                                    withAnimation(.spring()) {
                                        showSourceInfo.toggle() 
                                    }
                                }) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .padding(10)
                                        .background(
                                            Circle()
                                                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Modern search bar with animation
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(searchText.isEmpty ? .gray : .blue)
                                .padding(.leading, 12)
                                .animation(.spring(), value: searchText)
                            
                            TextField("Artikel suchen...", text: $searchText)
                                .font(.system(size: 16))
                                .padding(.vertical, 12)
                            
                            if !searchText.isEmpty {
                                Button(action: { 
                                    withAnimation(.spring()) {
                                        searchText = "" 
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }
                .frame(height: 140)
                .zIndex(2)
                
                // Server status info banner
                if showSourceInfo, let status = serverStatus {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(statusColor(for: status.status))
                            .frame(width: 10, height: 10)
                        
                        Text(status.message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { 
                            withAnimation(.spring()) {
                                showSourceInfo = false 
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
                
                // Content with modern styling for loading and error states
                ZStack {
                    if isLoading && articles.isEmpty {
                        LoadingView(message: "Neuigkeiten werden geladen...")
                    } else if let error = errorMessage {
                        ErrorView(message: error) {
                            loadArticles()
                        }
                    } else if filteredArticles.isEmpty {
                        if searchText.isEmpty {
                            EmptyStateView(
                                icon: "newspaper",
                                title: "Keine Neuigkeiten verfügbar",
                                message: serverStatusMessage()
                            )
                        } else {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "Keine Ergebnisse",
                                message: "Keine Ergebnisse für \"\(searchText)\""
                            )
                        }
                    } else {
                        // Articles list with modern styling and pull-to-refresh
                        ScrollViewWithOffset(axes: .vertical, showsIndicators: true, onOffsetChange: { offset in
                            scrollOffset = offset
                            
                            // Pull-to-refresh logic
                            if offset > 80 && !refreshing && !isLoading {
                                refreshing = true
                                loadArticles()
                            }
                        }) {
                            VStack(spacing: 0) {
                                // Pull-to-refresh indicator
                                if refreshing {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .padding()
                                        Spacer()
                                    }
                                }
                                
                                // Featured article (first article)
                                if !searchText.isEmpty || filteredArticles.isEmpty {
                                    // Skip featured article in search results
                                } else {
                                    FeaturedArticleCard(article: filteredArticles[0])
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedArticle = filteredArticles[0]
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 16)
                                }
                                
                                // Rest of the articles with staggered animation
                                LazyVStack(spacing: 16) {
                                    ForEach(Array(zip(searchText.isEmpty && !filteredArticles.isEmpty ? Array(filteredArticles.dropFirst()).indices : filteredArticles.indices, searchText.isEmpty && !filteredArticles.isEmpty ? Array(filteredArticles.dropFirst()) : filteredArticles)), id: \.1.id) { index, article in
                                        ArticleListItem(article: article, index: index)
                                            .onTapGesture {
                                                withAnimation(.spring()) {
                                                    selectedArticle = article
                                                }
                                            }
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.top, 16)
                                
                                // Bottom padding
                                Spacer(minLength: 30)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .onChange(of: refreshing) { newValue in
                    if !newValue {
                        // Reset refreshing state after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                refreshing = false
                            }
                        }
                    }
                }
            }
            
            // Article detail overlay with hero animation
            if let article = selectedArticle {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedArticle = nil
                        }
                    }
                
                FixedArticleDetailView(article: article, isPresented: Binding(
                    get: { selectedArticle != nil },
                    set: { if !$0 { selectedArticle = nil } }
                ))
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            fetchServerStatus()
            loadArticles()
        }
    }
    
    private func fetchServerStatus() {
        NetworkManager.shared.fetchServerStatus { status, error in
            if let status = status {
                self.serverStatus = status
            } else if let error = error {
                print("Error fetching server status: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadArticles() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.fetchWordPressArticles { articles, error in
            isLoading = false
            refreshing = false
            
            if let error = error {
                errorMessage = "Fehler beim Laden der Artikel: \(error.localizedDescription)"
            } else if let articles = articles {
                withAnimation(.spring()) {
                    self.articles = articles
                }
            } else {
                errorMessage = "Unbekannter Fehler beim Laden der Artikel"
            }
            
            // Refresh server status after loading articles
            fetchServerStatus()
        }
    }
    
    private func statusColor(for status: ServerStatus.Status) -> Color {
        switch status {
        case .online:
            return .green
        case .offline:
            return .red
        case .wordpressOffline:
            return .orange
        case .starting:
            return .blue
        case .error:
            return .red
        }
    }
    
    private func serverStatusMessage() -> String {
        if let status = serverStatus {
            switch status.status {
            case .wordpressOffline:
                return "Die Schul-Website ist nicht erreichbar. Es werden zwischengespeicherte Daten angezeigt."
            case .offline:
                return "Der Server ist offline. Bitte versuche es später erneut."
            case .error:
                return "Es ist ein Fehler aufgetreten: \(status.message)"
            case .starting:
                return "Der Server wird gestartet..."
            case .online:
                return "Zurzeit sind keine Artikel verfügbar."
            }
        } else {
            return "Keine Verbindung zum Server möglich."
        }
    }
}

// MARK: - Helper Views

// BlurView for modern UI
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// ScrollView with offset tracking for pull-to-refresh
struct ScrollViewWithOffset<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let onOffsetChange: (CGFloat) -> Void
    let content: Content
    
    init(axes: Axis.Set = .vertical, showsIndicators: Bool = true, onOffsetChange: @escaping (CGFloat) -> Void = { _ in }, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.onOffsetChange = onOffsetChange
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            GeometryReader { geometry in
                Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).minY)
            }
            .frame(width: 0, height: 0)
            
            content
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: onOffsetChange)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Loading state view
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Error state view
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    // Extract error type from message
    private var isServerOffline: Bool {
        message.contains("Server") && (message.contains("offline") || message.contains("nicht erreichbar"))
    }
    
    private var isNetworkError: Bool {
        message.contains("Netzwerk") || message.contains("Internet") || message.contains("Verbindung")
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon based on error type
            ZStack {
                Circle()
                    .fill(errorColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: errorIcon)
                    .font(.system(size: 40))
                    .foregroundColor(errorColor)
            }
            
            // Error title
            Text(errorTitle)
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
            
            // Error message
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Erneut versuchen")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(maxWidth: 280)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                }
                
                if isServerOffline {
                    Button(action: {
                        if let url = URL(string: "https://marienschule-bielefeld.de/") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Website im Browser öffnen")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 280)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.blue.opacity(0.2) : Color.white)
                                )
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Dynamic properties based on error type
    private var errorIcon: String {
        if isServerOffline {
            return "server.rack"
        } else if isNetworkError {
            return "wifi.slash"
        } else {
            return "exclamationmark.triangle"
        }
    }
    
    private var errorColor: Color {
        if isServerOffline {
            return .orange
        } else if isNetworkError {
            return .red
        } else {
            return .orange
        }
    }
    
    private var errorTitle: String {
        if isServerOffline {
            return "Server nicht erreichbar"
        } else if isNetworkError {
            return "Netzwerkfehler"
        } else {
            return "Fehler aufgetreten"
        }
    }
}

// Empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color.blue.opacity(0.6))
                .padding()
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                )
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Featured article card (large card for the first article)
struct FeaturedArticleCard: View {
    let article: WordPressArticle
    @State private var imageData: Data? = nil
    @State private var isLoadingImage = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack {
                if isLoadingImage {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 220)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                        )
                } else if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.blue.opacity(0.7))
                        )
                }
                
                // Gradient overlay for better text visibility
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                
                // Title overlay
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(formatDate(article.date))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.7))
                                )
                            
                            Text(article.title.plainText)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(cleanExcerpt(article.excerpt.plainText))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                        
                        Spacer()
                    }
                }
            }
            .cornerRadius(20)
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // First check if we have a cached image locally
        if let cachedImageData = NetworkManager.shared.getCachedImage(for: article.id) {
            self.imageData = cachedImageData
            return
        }
        
        // If no cached image, try to fetch from server
        isLoadingImage = true
        
        NetworkManager.shared.fetchImage(for: article) { data, error in
            isLoadingImage = false
            
            if let data = data {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.imageData = data
                }
            } else if let error = error {
                print("Error loading image: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "de_DE")
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            displayFormatter.locale = Locale(identifier: "de_DE")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // Helper function to clean excerpt text
    private func cleanExcerpt(_ text: String) -> String {
        var cleanedText = text
        
        // Remove WordPress ellipsis markers
        cleanedText = cleanedText.replacingOccurrences(of: "[…]", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "[&hellip;]", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "[&#8230;]", with: "")
        
        // Remove trailing ellipsis
        if cleanedText.hasSuffix("...") || cleanedText.hasSuffix("…") {
            cleanedText = cleanedText.replacingOccurrences(of: "\\.\\.\\.$", with: "", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: "…$", with: "", options: .regularExpression)
        }
        
        return cleanedText
    }
}

// Article list item (horizontal card for regular articles)
struct ArticleListItem: View {
    let article: WordPressArticle
    let index: Int
    @State private var imageData: Data? = nil
    @State private var isLoadingImage = false
    @State private var appeared = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            // Thumbnail
            ZStack {
                if isLoadingImage {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 100)
                        .cornerRadius(16)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                        )
                } else if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(16)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .cornerRadius(16)
                        .overlay(
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color.blue.opacity(0.6))
                        )
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title.plainText)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(cleanExcerpt(article.excerpt.plainText))
                    .font(.system(size: 14))
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(formatDate(article.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.7))
                        )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .opacity(appeared ? 1.0 : 0.0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            // Staggered animation for list items
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                appeared = true
            }
            loadImage()
        }
    }
    
    private func loadImage() {
        // First check if we have a cached image locally
        if let cachedImageData = NetworkManager.shared.getCachedImage(for: article.id) {
            self.imageData = cachedImageData
            return
        }
        
        // If no cached image, try to fetch from server
        isLoadingImage = true
        
        NetworkManager.shared.fetchImage(for: article) { data, error in
            isLoadingImage = false
            
            if let data = data {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.imageData = data
                }
            } else if let error = error {
                print("Error loading image: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "de_DE")
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            displayFormatter.locale = Locale(identifier: "de_DE")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // Helper function to clean excerpt text
    private func cleanExcerpt(_ text: String) -> String {
        var cleanedText = text
        
        // Remove WordPress ellipsis markers
        cleanedText = cleanedText.replacingOccurrences(of: "[…]", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "[&hellip;]", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "[&#8230;]", with: "")
        
        // Remove trailing ellipsis
        if cleanedText.hasSuffix("...") || cleanedText.hasSuffix("…") {
            cleanedText = cleanedText.replacingOccurrences(of: "\\.\\.\\.$", with: "", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: "…$", with: "", options: .regularExpression)
        }
        
        return cleanedText
    }
}

// Fixed article detail view with proper scaling
struct FixedArticleDetailView: View {
    let article: WordPressArticle
    @Binding var isPresented: Bool
    @State private var imageData: Data? = nil
    @State private var isLoadingImage = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isPresented = false
                    }
                
                // Article container
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { isPresented = false }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Zurück zu Neuigkeiten")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: article.link) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "safari")
                                Text("Im Browser öffnen")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                    
                    // Scrollable content
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .center, spacing: 0) {
                            let contentWidth = min(geometry.size.width * 0.9, 500)
                            
                            // Featured image
                            if isLoadingImage {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: contentWidth, height: min(200, geometry.size.height * 0.25))
                                    .cornerRadius(8)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.5)
                                    )
                                    .padding(.top, 16)
                            } else if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: contentWidth, height: min(200, geometry.size.height * 0.25))
                                    .cornerRadius(8)
                                    .clipped()
                                    .padding(.top, 16)
                            } else {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: contentWidth, height: min(200, geometry.size.height * 0.25))
                                    .cornerRadius(8)
                                    .overlay(
                                        Image(systemName: "newspaper")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    )
                                    .padding(.top, 16)
                            }
                            
                            // Article content
                            VStack(alignment: .leading, spacing: 16) {
                                // Title and date
                                Text(article.title.plainText)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 16)
                                    .frame(width: contentWidth, alignment: .leading)
                                
                                Text(formatDate(article.date))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(width: contentWidth, alignment: .leading)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                    .frame(width: contentWidth)
                                
                                // Content
                                ArticleContentView(htmlContent: article.content.rendered, viewWidth: contentWidth)
                                    .frame(width: contentWidth)
                                
                                // Bottom padding
                                Spacer(minLength: 30)
                            }
                        }
                        .frame(width: min(geometry.size.width * 0.95, 500))
                        .padding(.horizontal, 0)
                        .padding(.bottom, 16)
                    }
                }
                .frame(width: min(geometry.size.width * 0.95, 500), height: min(geometry.size.height * 0.95, 900))
                .background(colorScheme == .dark ? Color(.systemBackground) : Color.white)
                .cornerRadius(16)
                .shadow(radius: 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                loadImage()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func loadImage() {
        // First check if we have a cached image locally
        if let cachedImageData = NetworkManager.shared.getCachedImage(for: article.id) {
            self.imageData = cachedImageData
            return
        }
        
        // If no cached image, try to fetch from server
        isLoadingImage = true
        
        NetworkManager.shared.fetchImage(for: article) { data, error in
            isLoadingImage = false
            
            if let data = data {
                self.imageData = data
            } else if let error = error {
                print("Error loading image in detail: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "de_DE")
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "de_DE")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// Article content view
struct ArticleContentView: UIViewRepresentable {
    let htmlContent: String
    let viewWidth: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.dataDetectorTypes = .link
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // Set delegate to handle links
        textView.delegate = context.coordinator
        
        return textView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ArticleContentView
        
        init(_ parent: ArticleContentView) {
            self.parent = parent
        }
        
        // Handle link taps
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false
        }
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Determine text and background colors based on color scheme
        let textColor = colorScheme == .dark ? "#F2F2F2" : "#333333"
        let linkColor = colorScheme == .dark ? "#4DA6FF" : "#0066CC"
        let backgroundColor = "transparent"
        let quoteBackgroundColor = colorScheme == .dark ? "#2A2A2A" : "#F7F7F7"
        
        // Set a fixed width for the content
        let contentWidth = viewWidth
        
        // Process the HTML content to fix common WordPress issues
        let processedContent = processWordPressContent(htmlContent)
        
        // Prepare HTML with modern styling
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=\(contentWidth), initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    color: \(textColor);
                    background-color: \(backgroundColor);
                    margin: 0;
                    padding: 0;
                    width: \(contentWidth)px;
                    overflow-wrap: break-word;
                    word-wrap: break-word;
                    word-break: break-word;
                    overflow-x: hidden;
                    -webkit-text-size-adjust: 100%;
                }
                * {
                    max-width: 100%;
                    box-sizing: border-box;
                }
                img {
                    max-width: 100%;
                    height: auto !important;
                    display: block;
                    margin: 20px auto;
                    border-radius: 8px;
                }
                a {
                    color: \(linkColor);
                    text-decoration: none;
                }
                p {
                    margin-bottom: 16px;
                    margin-top: 0;
                    max-width: 100%;
                    overflow-wrap: break-word;
                    width: 100%;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 700;
                    line-height: 1.3;
                    max-width: 100%;
                    overflow-wrap: break-word;
                    width: 100%;
                }
                h1 {
                    font-size: 24px;
                }
                h2 {
                    font-size: 22px;
                }
                h3 {
                    font-size: 20px;
                }
                ul, ol {
                    padding-left: 24px;
                    margin-bottom: 16px;
                    max-width: 100%;
                    width: calc(100% - 24px);
                }
                li {
                    margin-bottom: 8px;
                    overflow-wrap: break-word;
                }
                blockquote {
                    border-left: 4px solid \(linkColor);
                    padding: 12px 16px;
                    margin: 20px 0;
                    background-color: \(quoteBackgroundColor);
                    border-radius: 4px;
                    max-width: calc(100% - 36px);
                    overflow-wrap: break-word;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 24px 0;
                    overflow-x: scroll;
                    display: block;
                    max-width: 100%;
                }
                th, td {
                    border: 1px solid #DDDDDD;
                    padding: 8px;
                    text-align: left;
                    font-size: 14px;
                }
                th {
                    background-color: \(quoteBackgroundColor);
                    font-weight: 600;
                }
                pre {
                    background-color: \(quoteBackgroundColor);
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                    margin: 16px 0;
                    max-width: 100%;
                    white-space: pre-wrap;
                    width: 100%;
                }
                code {
                    font-family: SFMono-Regular, Menlo, Monaco, Consolas, monospace;
                    font-size: 14px;
                }
                iframe {
                    max-width: 100%;
                    height: auto;
                    margin: 20px 0;
                    width: 100%;
                }
                figure {
                    margin: 20px 0;
                    max-width: 100%;
                    width: 100%;
                }
                figcaption {
                    font-size: 14px;
                    color: #666;
                    text-align: center;
                    margin-top: 8px;
                    width: 100%;
                }
                .wp-block-image {
                    width: 100%;
                    margin: 20px 0;
                }
                .wp-block-image img {
                    max-width: 100%;
                    height: auto !important;
                    width: auto;
                }
                .wp-block-embed {
                    width: 100%;
                    margin: 20px 0;
                }
                .wp-block-embed iframe {
                    max-width: 100%;
                    width: 100%;
                }
                div {
                    max-width: 100%;
                    width: 100%;
                }
                /* Fix for WordPress specific elements */
                .wp-block-separator {
                    border: none;
                    height: 1px;
                    background-color: #ddd;
                    margin: 20px 0;
                }
                .wp-block-quote {
                    border-left: 4px solid \(linkColor);
                    padding: 12px 16px;
                    margin: 20px 0;
                    background-color: \(quoteBackgroundColor);
                    border-radius: 4px;
                }
                .wp-block-gallery {
                    display: flex;
                    flex-wrap: wrap;
                    list-style-type: none;
                    padding: 0;
                    margin: 0;
                }
                .blocks-gallery-item {
                    margin: 8px;
                    display: flex;
                    flex-grow: 1;
                    flex-direction: column;
                    justify-content: center;
                    position: relative;
                }
            </style>
        </head>
        <body>
            \(processedContent)
        </body>
        </html>
        """
        
        if let attributedString = try? NSAttributedString(
            data: Data(styledHTML.utf8),
            options: [.documentType: NSAttributedString.DocumentType.html,
                     .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) {
            uiView.attributedText = attributedString
        } else {
            uiView.text = processedContent
        }
        
        // Set a fixed width for the text view
        uiView.frame.size.width = contentWidth
        
        // Resize the UITextView to fit its content
        let newSize = uiView.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
        uiView.frame.size = CGSize(width: contentWidth, height: newSize.height)
        
        // Ensure the text view is large enough to display all content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let finalSize = uiView.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
            if finalSize.height > newSize.height {
                uiView.frame.size = CGSize(width: contentWidth, height: finalSize.height)
            }
        }
    }
    
    // Helper method to process WordPress content
    private func processWordPressContent(_ content: String) -> String {
        // Remove any truncation markers that WordPress might add
        var processedContent = content
        
        // Replace any "[&hellip;]" or similar truncation markers
        processedContent = processedContent.replacingOccurrences(of: "\\[&hellip;\\]", with: "", options: .regularExpression)
        processedContent = processedContent.replacingOccurrences(of: "\\[…\\]", with: "", options: .regularExpression)
        processedContent = processedContent.replacingOccurrences(of: "\\[&\\#8230;\\]", with: "", options: .regularExpression)
        
        // Fix any incomplete HTML tags
        if !processedContent.contains("</p>") && processedContent.contains("<p>") {
            processedContent += "</p>"
        }
        
        // Fix WordPress image sizing issues
        processedContent = processedContent.replacingOccurrences(
            of: "width=\"[0-9]+\"",
            with: "width=\"100%\"",
            options: .regularExpression
        )
        
        processedContent = processedContent.replacingOccurrences(
            of: "height=\"[0-9]+\"",
            with: "height=\"auto\"",
            options: .regularExpression
        )
        
        // Fix WordPress iframes
        processedContent = processedContent.replacingOccurrences(
            of: "<iframe([^>]+)>",
            with: "<iframe$1 width=\"100%\" frameborder=\"0\" allowfullscreen>",
            options: .regularExpression
        )
        
        // Fix WordPress "read more" links
        processedContent = processedContent.replacingOccurrences(
            of: "<a class=\"more-link\"[^>]*>.*?</a>",
            with: "",
            options: .regularExpression
        )
        
        // Fix WordPress protected content placeholders
        processedContent = processedContent.replacingOccurrences(
            of: "\\(Passwortgeschützer Inhalt\\)",
            with: "",
            options: .regularExpression
        )
        
        // Fix WordPress excerpt ellipsis
        processedContent = processedContent.replacingOccurrences(
            of: "&hellip;",
            with: "...",
            options: .regularExpression
        )
        
        // Remove any WordPress shortcodes that might be causing issues
        processedContent = processedContent.replacingOccurrences(
            of: "\\[\\/?[^\\]]+\\]",
            with: "",
            options: .regularExpression
        )
        
        // Fix abrupt ending with ellipsis
        if processedContent.hasSuffix("...") || processedContent.hasSuffix("…") {
            // If content ends with ellipsis, it might be truncated
            processedContent = processedContent.replacingOccurrences(of: "\\.\\.\\.$", with: "", options: .regularExpression)
            processedContent = processedContent.replacingOccurrences(of: "…$", with: "", options: .regularExpression)
        }
        
        // Fix HTML entities that might be causing truncation
        processedContent = processedContent.replacingOccurrences(of: "&nbsp;", with: " ", options: .regularExpression)
        processedContent = processedContent.replacingOccurrences(of: "&amp;", with: "&", options: .regularExpression)
        processedContent = processedContent.replacingOccurrences(of: "&lt;", with: "<", options: .regularExpression)
        processedContent = processedContent.replacingOccurrences(of: "&gt;", with: ">", options: .regularExpression)
        
        // Fix potential truncation in the middle of a paragraph
        if !processedContent.hasSuffix("</p>") && !processedContent.hasSuffix("</div>") {
            if processedContent.contains("<p>") {
                processedContent += "</p>"
            }
        }
        
        return processedContent
    }
} 