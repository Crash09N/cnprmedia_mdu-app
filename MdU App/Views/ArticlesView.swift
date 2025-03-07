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
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Button(action: { currentPage = .home }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .frame(width: 44)
                        
                        Spacer()
                        
                        Text("Neuigkeiten")
                            .font(.system(size: 22, weight: .bold))
                        
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
                            }
                            
                            Button(action: { showSourceInfo.toggle() }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(width: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Modern search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("Artikel suchen...", text: $searchText)
                            .font(.system(size: 16))
                            .padding(.vertical, 10)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                if showSourceInfo {
                    // Data source info banner with modern styling
                    HStack(spacing: 10) {
                        Circle()
                            .fill(usingBackend ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        
                        Text(usingBackend ? "Daten vom Backend-Server" : "Daten direkt von der Website")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { showSourceInfo = false }) {
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
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }
                
                // Content with modern styling for loading and error states
                if isLoading {
                    Spacer()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            )
                        
                        Text("Neuigkeiten werden geladen...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            )
                        
                        Text(error)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { loadArticles() }) {
                            Text("Erneut versuchen")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                )
                        }
                    }
                    Spacer()
                } else if filteredArticles.isEmpty {
                    if searchText.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "newspaper")
                                .font(.system(size: 40))
                                .foregroundColor(Color.blue.opacity(0.6))
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                )
                            
                            Text("Keine Neuigkeiten verfügbar")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(Color.blue.opacity(0.6))
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                )
                            
                            Text("Keine Ergebnisse für \"\(searchText)\"")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                } else {
                    // Articles grid/list with modern styling
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Featured article (first article)
                            if !searchText.isEmpty || filteredArticles.isEmpty {
                                // Skip featured article in search results
                            } else {
                                FeaturedArticleCard(article: filteredArticles[0])
                                    .onTapGesture {
                                        selectedArticle = filteredArticles[0]
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 16)
                            }
                            
                            // Rest of the articles
                            ForEach(searchText.isEmpty && !filteredArticles.isEmpty ? Array(filteredArticles.dropFirst()) : filteredArticles) { article in
                                ArticleListItem(article: article)
                                    .onTapGesture {
                                        selectedArticle = article
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 16)
                            }
                            
                            // Bottom padding
                            Spacer(minLength: 30)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            
            // Article detail overlay
            if let article = selectedArticle {
                FixedArticleDetailView(article: article, isPresented: Binding(
                    get: { selectedArticle != nil },
                    set: { if !$0 { selectedArticle = nil } }
                ))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadArticles()
        }
    }
    
    private func loadArticles() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.fetchWordPressArticles { articles, error in
            isLoading = false
            
            // Update the data source indicator
            self.usingBackend = NetworkManager.shared.isUsingBackend()
            
            if let error = error {
                errorMessage = "Fehler beim Laden der Artikel: \(error.localizedDescription)"
            } else if let articles = articles {
                self.articles = articles
            } else {
                errorMessage = "Unbekannter Fehler beim Laden der Artikel"
            }
        }
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
                        .frame(height: 200)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                        )
                } else if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 200)
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDate(article.date))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.7))
                                .cornerRadius(4)
                            
                            Text(article.title.plainText)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                        
                        Spacer()
                    }
                }
            }
            .cornerRadius(16)
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
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
                self.imageData = data
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
}

// Article list item (horizontal card for regular articles)
struct ArticleListItem: View {
    let article: WordPressArticle
    @State private var imageData: Data? = nil
    @State private var isLoadingImage = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            // Thumbnail
            ZStack {
                if isLoadingImage {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 100)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                        )
                } else if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .cornerRadius(12)
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
                
                Text(article.excerpt.plainText)
                    .font(.system(size: 14))
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(formatDate(article.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
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
                self.imageData = data
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
                                Text("Zurück")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("Artikel")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: article.link) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(systemName: "safari")
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
                .frame(width: min(geometry.size.width * 0.95, 500), height: min(geometry.size.height * 0.9, 800))
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
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Determine text and background colors based on color scheme
        let textColor = colorScheme == .dark ? "#F2F2F2" : "#333333"
        let linkColor = colorScheme == .dark ? "#4DA6FF" : "#0066CC"
        let backgroundColor = "transparent"
        let quoteBackgroundColor = colorScheme == .dark ? "#2A2A2A" : "#F7F7F7"
        
        // Set a fixed width for the content
        let contentWidth = viewWidth
        
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
                    height: auto;
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
                    height: auto;
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
            </style>
        </head>
        <body>
            \(htmlContent)
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
            uiView.text = htmlContent
        }
        
        // Set a fixed width for the text view
        uiView.frame.size.width = contentWidth
        
        // Resize the UITextView to fit its content
        let newSize = uiView.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
        uiView.frame.size = CGSize(width: contentWidth, height: newSize.height)
    }
} 