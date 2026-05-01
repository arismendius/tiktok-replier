import SwiftUI
import WebKit

struct LoginWebView: NSViewRepresentable {
    @Binding var isLoggedIn: Bool

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: URL(string: "https://www.tiktok.com/login")!))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(isLoggedIn: $isLoggedIn) }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoggedIn: Bool
        init(isLoggedIn: Binding<Bool>) { _isLoggedIn = isLoggedIn }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                DispatchQueue.main.async {
                    self.isLoggedIn = cookies.contains { $0.domain.contains("tiktok.com") && $0.name == "sessionid" }
                }
            }
        }
    }
}
