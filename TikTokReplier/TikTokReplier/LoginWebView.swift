import SwiftUI
import WebKit

struct LoginWebView: NSViewRepresentable {
    @Binding var isLoggedIn: Bool

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        // Use mobile Safari UA — TikTok serves a simpler page that renders in WKWebView
        config.applicationNameForUserAgent = "Mobile/15E148 Safari/604.1"

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.pageZoom = 1.0
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Mobile/15E148 Safari/604.1"

        var req = URLRequest(url: URL(string: "https://www.tiktok.com/login")!)
        req.setValue("https://www.tiktok.com", forHTTPHeaderField: "Referer")
        webView.load(req)
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
