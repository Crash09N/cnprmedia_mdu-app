import SwiftUI
import Foundation
import WebKit
import Combine

struct FilesView: View {
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var webdavFiles: [WebDAVFile] = []
    @State private var webdavError: String?
    @State private var lastRefreshTime: Date?
    
    // WebDAV connection details
    @State private var webdavUrl: String?
    @State private var webdavUsername: String?
    @State private var webdavPassword: String?
    
    // Cache settings
    private let cacheExpirationTime: TimeInterval = 5 * 60 // 5 minutes
    private let webdavTimeout: TimeInterval = 60 // 60 seconds timeout
    
    // Fetch WebDAV credentials from user profile
    private func fetchWebDAVCredentials() {
        print("⚙️ Fetching WebDAV credentials...")
        
        // Get the current user from UserDefaults
        if let user = UserDefaults.standard.object(forKey: "currentUser") as? [String: Any] {
            // Extract webdavUrl
            if let webdavUrl = user["webdavUrl"] as? String {
                self.webdavUrl = webdavUrl
                print("📁 Found WebDAV URL: \(webdavUrl)")
                
                // Extract username from webdavUrl (everything after the last slash)
                if let lastSlashIndex = webdavUrl.lastIndex(of: "/") {
                    let startIndex = webdavUrl.index(after: lastSlashIndex)
                    let username = String(webdavUrl[startIndex..<webdavUrl.endIndex])
                    if !username.isEmpty {
                        self.webdavUsername = username
                        print("👤 Extracted username from URL: \(username)")
                    }
                }
                
                // Use the password that was entered at login
                if let password = UserDefaults.standard.string(forKey: "userPassword") {
                    self.webdavPassword = password
                    print("🔑 Found password from login")
                } else {
                    print("⚠️ No password found in UserDefaults")
                }
            } else {
                print("⚠️ No WebDAV URL found in user profile")
            }
        } else {
            print("⚠️ No user found in UserDefaults")
        }
        
        // If no WebDAV URL is found, try to use the default Nextcloud URL
        if webdavUrl == nil && webdavUsername != nil {
            webdavUrl = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/remote.php/dav/files/\(webdavUsername!)/"
            print("🔄 Using constructed WebDAV URL: \(webdavUrl!)")
        }
        
        // For testing purposes, if no credentials are found, use default values
        if webdavUsername == nil || webdavPassword == nil || webdavUrl == nil {
            #if DEBUG
            print("⚠️ Using default WebDAV credentials for testing")
            webdavUsername = "test.user"
            webdavPassword = "test.password"
            webdavUrl = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/remote.php/dav/files/test.user/"
            #endif
        }
        
        // Log the WebDAV credentials (for debugging)
        #if DEBUG
        print("📊 WebDAV Connection Details:")
        print("  URL: \(webdavUrl ?? "nil")")
        print("  Username: \(webdavUsername ?? "nil")")
        print("  Password: \(webdavPassword != nil ? "****" : "nil")")
        #endif
    }
    
    // WebDAV file structure
    struct WebDAVFile: Identifiable, Codable {
        let id: UUID
        let name: String
        let path: String
        let size: Int64
        let isDirectory: Bool
        let lastModified: Date
    }
    
    // Load cached files if available
    private func loadCachedFiles() -> [WebDAVFile]? {
        print("🔍 Checking for cached WebDAV files...")
        
        guard let cacheURL = getCacheFileURL() else {
            print("⚠️ Could not determine cache file URL")
            return nil
        }
        
        do {
            // Check if cache exists and is not expired
            let attributes = try FileManager.default.attributesOfItem(atPath: cacheURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                let cacheAge = Date().timeIntervalSince(modificationDate)
                
                if cacheAge < cacheExpirationTime {
                    print("✅ Found valid cache (age: \(Int(cacheAge))s)")
                    
                    let data = try Data(contentsOf: cacheURL)
                    let decoder = JSONDecoder()
                    let cachedFiles = try decoder.decode([WebDAVFile].self, from: data)
                    
                    print("📂 Loaded \(cachedFiles.count) files from cache")
                    return cachedFiles
                } else {
                    print("⏱️ Cache expired (age: \(Int(cacheAge))s > \(Int(cacheExpirationTime))s)")
                }
            }
        } catch {
            print("⚠️ Error loading cache: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // Save files to cache
    private func saveFilesToCache(_ files: [WebDAVFile]) {
        print("💾 Saving \(files.count) files to cache...")
        
        guard let cacheURL = getCacheFileURL() else {
            print("⚠️ Could not determine cache file URL")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(files)
            try data.write(to: cacheURL)
            print("✅ Cache saved successfully")
        } catch {
            print("⚠️ Error saving cache: \(error.localizedDescription)")
        }
    }
    
    // Get cache file URL
    private func getCacheFileURL() -> URL? {
        guard let username = webdavUsername else { return nil }
        
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return cacheDirectory?.appendingPathComponent("webdav_\(username)_cache.json")
    }
    
    // WebDAV file provider with caching
    private func fetchWebDAVFiles() {
        print("🔄 Starting WebDAV file fetch...")
        
        // Check if we need to refresh based on cache
        if let lastRefresh = lastRefreshTime, Date().timeIntervalSince(lastRefresh) < cacheExpirationTime {
            print("⏱️ Last refresh was recent, checking cache...")
            if let cachedFiles = loadCachedFiles(), !cachedFiles.isEmpty {
                print("✅ Using cached files")
                self.webdavFiles = cachedFiles
                return
            }
        }
        
        guard let urlString = webdavUrl,
              let username = webdavUsername,
              let password = webdavPassword,
              let url = URL(string: urlString) else {
            webdavError = "Keine WebDAV-Anmeldeinformationen gefunden"
            print("❌ Missing WebDAV credentials")
            return
        }
        
        print("🌐 Connecting to WebDAV server: \(url.host ?? "unknown host")")
        
        isLoading = true
        webdavFiles = []
        webdavError = nil
        
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = webdavTimeout
        configuration.timeoutIntervalForResource = webdavTimeout
        
        print("⏱️ Set timeout to \(webdavTimeout) seconds")
        
        let session = URLSession(configuration: configuration)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PROPFIND"
        request.setValue("1", forHTTPHeaderField: "Depth")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        
        // Basic authentication
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            webdavError = "Fehler bei der Authentifizierung"
            isLoading = false
            print("❌ Authentication error - could not encode credentials")
            return
        }
        
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        print("🔒 Added authentication headers")
        print("📤 Sending WebDAV PROPFIND request...")
        
        let startTime = Date()
        
        let task = session.dataTask(with: request) { (data, response, error) in
            let requestDuration = Date().timeIntervalSince(startTime)
            print("⏱️ WebDAV request completed in \(String(format: "%.2f", requestDuration)) seconds")
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastRefreshTime = Date()
                
                if let error = error {
                    self.webdavError = "Fehler: \(error.localizedDescription)"
                    print("❌ Network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 Received response with status code: \(httpResponse.statusCode)")
                    
                    if !(200...299).contains(httpResponse.statusCode) {
                        self.webdavError = "Server-Fehler: \(httpResponse.statusCode)"
                        print("❌ HTTP error: \(httpResponse.statusCode)")
                        return
                    }
                }
                
                guard let data = data else {
                    self.webdavError = "Keine Daten vom Server erhalten"
                    print("❌ No data received from server")
                    return
                }
                
                print("📦 Received \(data.count) bytes of data")
                
                // Parse XML response
                do {
                    let xmlString = String(data: data, encoding: .utf8) ?? ""
                    print("🔍 Parsing WebDAV XML response...")
                    
                    let parseStartTime = Date()
                    let files = try self.parseWebDAVResponse(xmlString)
                    let parseDuration = Date().timeIntervalSince(parseStartTime)
                    
                    print("✅ Parsed \(files.count) files in \(String(format: "%.2f", parseDuration)) seconds")
                    
                    self.webdavFiles = files
                    
                    // Save to cache
                    self.saveFilesToCache(files)
                    
                } catch {
                    self.webdavError = "Fehler beim Parsen der Dateien: \(error.localizedDescription)"
                    print("❌ XML parsing error: \(error.localizedDescription)")
                }
            }
        }
        
        print("🚀 Starting WebDAV request...")
        task.resume()
    }
    
    // XML parsing for WebDAV response
    private func parseWebDAVResponse(_ xmlString: String) throws -> [WebDAVFile] {
        // Implement basic XML parsing for WebDAV PROPFIND response
        var files: [WebDAVFile] = []
        
        // Use a simple regex to extract file information
        let pattern = #"<d:href>([^<]+)</d:href>.*?<d:getcontentlength>(\d+)</d:getcontentlength>.*?<d:getlastmodified>([^<]+)</d:getlastmodified>"#
        
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(xmlString.startIndex..<xmlString.endIndex, in: xmlString)
        
        let matches = regex.matches(in: xmlString, options: [], range: range)
        print("🔢 Found \(matches.count) potential files in XML")
        
        for match in matches {
            // Extract filename from href
            if let hrefRange = Range(match.range(at: 1), in: xmlString) {
                let fullPath = String(xmlString[hrefRange])
                let filename = fullPath
                    .removingPercentEncoding?
                    .components(separatedBy: "/")
                    .last ?? ""
                
                // Skip empty or root directory entries
                guard !filename.isEmpty && filename != "." else { continue }
                
                // Extract file size
                if let sizeRange = Range(match.range(at: 2), in: xmlString),
                   let size = Int64(xmlString[sizeRange]) {
                    
                    // Extract last modified date
                    if let dateRange = Range(match.range(at: 3), in: xmlString) {
                        let dateString = String(xmlString[dateRange])
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                        
                        let lastModified = dateFormatter.date(from: dateString) ?? Date()
                        
                        let file = WebDAVFile(
                            id: UUID(),
                            name: filename,
                            path: fullPath,
                            size: size,
                            isDirectory: filename.hasSuffix("/"),
                            lastModified: lastModified
                        )
                        
                        files.append(file)
                    }
                }
            }
        }
        
        return files
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Custom search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Dateien suchen", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding()
                    
                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text("Verbinde mit WebDAV Server...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if let error = webdavError {
                        // Error view
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.red)
                            
                            Text("WebDAV-Fehler")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(error)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button(action: fetchWebDAVFiles) {
                                Text("Erneut versuchen")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    } else if webdavFiles.isEmpty {
                        FilesEmptyStateView(
                            title: "Keine WebDAV-Dateien",
                            message: "Verbinde dich mit deinem Nextcloud-Konto, um Dateien zu sehen."
                        )
                    } else {
                        VStack {
                            if let lastRefresh = lastRefreshTime {
                                Text("Letztes Update: \(timeAgoString(from: lastRefresh))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                            }
                            
                            List {
                                ForEach(webdavFiles.filter { 
                                    searchText.isEmpty || 
                                    $0.name.lowercased().contains(searchText.lowercased()) 
                                }) { file in
                                    WebDAVFileRow(file: file)
                                }
                            }
                            .listStyle(InsetGroupedListStyle())
                        }
                    }
                }
            }
            .navigationTitle("WebDAV Dateien")
            .navigationBarItems(
                trailing: Button(action: fetchWebDAVFiles) {
                    Image(systemName: "arrow.clockwise")
                }
            )
        }
        .onAppear {
            print("📱 FilesView appeared")
            fetchWebDAVCredentials()
            
            // Try to load from cache first
            if let cachedFiles = loadCachedFiles() {
                webdavFiles = cachedFiles
                lastRefreshTime = Date()
            }
            
            // Then fetch fresh data
            fetchWebDAVFiles()
        }
    }
    
    // Helper function to format time ago string
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "vor \(seconds) Sekunden"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "vor \(minutes) Minuten"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "vor \(hours) Stunden"
        } else {
            let days = seconds / 86400
            return "vor \(days) Tagen"
        }
    }
}

// WebDAV File Row
struct WebDAVFileRow: View {
    let file: FilesView.WebDAVFile
    
    var body: some View {
        HStack {
            // File type icon
            Image(systemName: fileIcon)
                .foregroundColor(fileColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.system(size: 16, weight: .medium))
                
                HStack {
                    Text(formattedFileSize)
                    Text("•")
                    Text(file.lastModified, style: .date)
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Folder or file indicator
            if file.isDirectory {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Compute file icon based on file extension
    private var fileIcon: String {
        let lowercaseName = file.name.lowercased()
        
        if file.isDirectory {
            return "folder.fill"
        }
        
        if lowercaseName.hasSuffix(".pdf") {
            return "doc.fill"
        } else if lowercaseName.hasSuffix(".txt") || lowercaseName.hasSuffix(".md") {
            return "doc.text.fill"
        } else if lowercaseName.hasSuffix(".jpg") || lowercaseName.hasSuffix(".png") || lowercaseName.hasSuffix(".jpeg") {
            return "photo.fill"
        } else if lowercaseName.hasSuffix(".pptx") || lowercaseName.hasSuffix(".ppt") {
            return "chart.bar.doc.horizontal.fill"
        } else if lowercaseName.hasSuffix(".xlsx") || lowercaseName.hasSuffix(".xls") {
            return "doc.richtext.fill"
        } else if lowercaseName.hasSuffix(".docx") || lowercaseName.hasSuffix(".doc") {
            return "doc.text.fill"
        }
        
        return "doc.fill"
    }
    
    // Compute file color based on file type
    private var fileColor: Color {
        let lowercaseName = file.name.lowercased()
        
        if file.isDirectory {
            return .blue
        }
        
        if lowercaseName.hasSuffix(".pdf") {
            return .red
        } else if lowercaseName.hasSuffix(".txt") || lowercaseName.hasSuffix(".md") {
            return .blue
        } else if lowercaseName.hasSuffix(".jpg") || lowercaseName.hasSuffix(".png") || lowercaseName.hasSuffix(".jpeg") {
            return .green
        } else if lowercaseName.hasSuffix(".pptx") || lowercaseName.hasSuffix(".ppt") {
            return .orange
        } else if lowercaseName.hasSuffix(".xlsx") || lowercaseName.hasSuffix(".xls") {
            return .green
        } else if lowercaseName.hasSuffix(".docx") || lowercaseName.hasSuffix(".doc") {
            return .blue
        }
        
        return .gray
    }
    
    // Format file size
    private var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: file.size)
    }
}

// Updated Empty State View to support custom messages
struct FilesEmptyStateView: View {
    var title: String = "Keine Dateien vorhanden"
    var message: String = "Füge neue Dateien hinzu, um sie hier zu sehen"
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    FilesView()
} 