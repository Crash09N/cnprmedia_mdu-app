import SwiftUI

struct FilesView: View {
    @State private var files: [FileItem] = []
    @State private var searchText = ""
    @State private var showingAddFile = false
    @State private var isLoading = false
    
    var filteredFiles: [FileItem] {
        if searchText.isEmpty {
            return files
        } else {
            return files.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else if files.isEmpty {
                        FilesEmptyStateView()
                    } else {
                        List {
                            ForEach(filteredFiles) { file in
                                FileRow(file: file)
                            }
                            .onDelete(perform: deleteFiles)
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle("Dateien")
            .navigationBarItems(
                trailing: Button(action: { showingAddFile = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddFile) {
                AddFileView(files: $files)
            }
            .onAppear(perform: loadFiles)
        }
    }
    
    private func loadFiles() {
        isLoading = true
        // TODO: Implement file loading logic
        // For now, we'll use sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            files = [
                FileItem(id: UUID(), name: "Hausaufgaben.pdf", type: .pdf, size: "2.4 MB", date: Date()),
                FileItem(id: UUID(), name: "Notizen.txt", type: .text, size: "12 KB", date: Date()),
                FileItem(id: UUID(), name: "Präsentation.pptx", type: .presentation, size: "5.1 MB", date: Date())
            ]
            isLoading = false
        }
    }
    
    private func deleteFiles(at offsets: IndexSet) {
        files.remove(atOffsets: offsets)
    }
}

struct FileItem: Identifiable {
    let id: UUID
    let name: String
    let type: FileType
    let size: String
    let date: Date
    
    enum FileType {
        case pdf, text, image, presentation, other
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .text: return "doc.text.fill"
            case .image: return "photo.fill"
            case .presentation: return "chart.bar.doc.horizontal.fill"
            case .other: return "doc.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pdf: return .red
            case .text: return .blue
            case .image: return .green
            case .presentation: return .orange
            case .other: return .gray
            }
        }
    }
}

struct FileRow: View {
    let file: FileItem
    
    var body: some View {
        HStack {
            Image(systemName: file.type.icon)
                .foregroundColor(file.type.color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.system(size: 16, weight: .medium))
                
                HStack {
                    Text(file.size)
                    Text("•")
                    Text(file.date, style: .date)
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Implement share action
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Dateien suchen", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct FilesEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Keine Dateien vorhanden")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Füge neue Dateien hinzu, um sie hier zu sehen")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct AddFileView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var files: [FileItem]
    @State private var fileName = ""
    @State private var selectedType: FileItem.FileType = .pdf
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dateidetails")) {
                    TextField("Dateiname", text: $fileName)
                    
                    Picker("Dateityp", selection: $selectedType) {
                        Text("PDF").tag(FileItem.FileType.pdf)
                        Text("Text").tag(FileItem.FileType.text)
                        Text("Bild").tag(FileItem.FileType.image)
                        Text("Präsentation").tag(FileItem.FileType.presentation)
                        Text("Andere").tag(FileItem.FileType.other)
                    }
                }
            }
            .navigationTitle("Neue Datei")
            .navigationBarItems(
                leading: Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Hinzufügen") {
                    addFile()
                }
                .disabled(fileName.isEmpty)
            )
        }
    }
    
    private func addFile() {
        let newFile = FileItem(
            id: UUID(),
            name: fileName,
            type: selectedType,
            size: "0 KB",
            date: Date()
        )
        files.append(newFile)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    FilesView()
} 