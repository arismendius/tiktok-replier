import SwiftUI
import WebKit

struct LoginWebView: NSViewRepresentable {
    @Binding var isLoggedIn: Bool

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        // Spoof a real Safari/macOS User-Agent so TikTok renders the full login UI
        config.applicationNameForUserAgent = "Version/17.4.1 Safari/605.1.15"

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15"

        var req = URLRequest(url: URL(string: "https://www.tiktok.com/login/phone-or-email/email")!)
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
