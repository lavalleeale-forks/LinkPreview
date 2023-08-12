import LinkPresentation
import SwiftUI

public struct LinkPreview: View {
    let url: URL?
    
    @State private var isPresented: Bool = false
    @State private var metaData: LPLinkMetadata? = nil
    
    var backgroundColor: Color = .init(.systemGray5)
    var primaryFontColor: Color = .primary
    var secondaryFontColor: Color = .secondary
    var titleLineLimit: Int = 3
    var type: LinkPreviewType = .auto
    
    public init(url: URL?) {
        self.url = url
    }
    
    public var body: some View {
        if let url = url {
            if let metaData = metaData {
                Button(action: {
                    if UIApplication.shared.canOpenURL(url) {
                        self.isPresented.toggle()
                    }
                }, label: {
                    LinkPreviewDesign(metaData: metaData, type: type, backgroundColor: backgroundColor, primaryFontColor: primaryFontColor, secondaryFontColor: secondaryFontColor, titleLineLimit: titleLineLimit)
                })
                .buttonStyle(LinkButton())
                .fullScreenCover(isPresented: $isPresented) {
                    SfSafariView(url: url)
                        .edgesIgnoringSafeArea(.all)
                }
                .animation(.spring(), value: metaData)
            }
            else {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: secondaryFontColor))
                    
                    if type != .small {
                        Text(url.host ?? "")
                            .font(.caption)
                            .foregroundColor(primaryFontColor)
                    }
                }
                .padding(.horizontal, type == .small ? 0 : 12)
                .padding(.vertical, type == .small ? 0 : 6)
                .background(
                    Capsule()
                        .foregroundColor(type == .small ? .clear : backgroundColor)
                )
                .onAppear(perform: {
                    if metaData == nil {
                        MetadataStorage.getMetadata(url: url) { metaData in
                            withAnimation(.spring()) {
                                self.metaData = metaData
                            }
                        }
                    }
                })
                .onTapGesture {
                    if UIApplication.shared.canOpenURL(url) {
                        self.isPresented.toggle()
                    }
                }
                .fullScreenCover(isPresented: $isPresented) {
                    SfSafariView(url: url)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
}

public struct MetadataStorage {
    private static let storage = UserDefaults.standard
    
    public static func store(_ metadata: LPLinkMetadata) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
            var metadatas = storage.dictionary(forKey: "Metadata") as? [String: Data] ?? [String: Data]()
            while metadatas.count > 200 {
                metadatas.removeValue(forKey: metadatas.randomElement()!.key)
            }
            if let url = metadata.originalURL?.absoluteString {
                metadatas[url] = data
                storage.set(metadatas, forKey: "Metadata")
            }
        }
        catch {
            print("Failed storing metadata with error \(error as NSError)")
        }
    }
    
    public static func metadata(for url: URL) -> LPLinkMetadata? {
        guard let metadatas = storage.dictionary(forKey: "Metadata") as? [String: Data] else {
            return nil
        }
        guard let data = metadatas[url.absoluteString] else {
            return nil
        }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
        }
        catch {
            print("Failed to unarchive metadata with error \(error as NSError)")
            return nil
        }
    }
    
    public static func getMetadata(url: URL, completion: @escaping (LPLinkMetadata?)->Void) {
        if let metadata = MetadataStorage.metadata(for: url) {
            completion(metadata)
            return
        }
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { meta, _ in
            guard let meta = meta else { return }
            MetadataStorage.store(meta)
                completion(meta)
        }
    }
}

struct LinkButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}
