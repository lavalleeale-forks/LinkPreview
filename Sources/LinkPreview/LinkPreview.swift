import SwiftUI
import LinkPresentation

public struct LinkPreview: View {
    let url: URL?
    
    @State private var isPresented: Bool = false
    @State private var metaData: LPLinkMetadata? = nil
    
    var backgroundColor: Color = Color(.systemGray5)
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
                HStack(spacing: 10){
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
                    getMetaData(url: url)
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
    
    func getMetaData(url: URL) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { meta, err in
            guard let meta = meta else {return}
            withAnimation(.spring()) {
                self.metaData = meta
            }
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
