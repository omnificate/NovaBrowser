// FindInPageBar.swift
// NovaBrowser - Find in page search bar

import SwiftUI

struct FindInPageBar: View {
    let tab: BrowserTab?
    @State private var query = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))

                TextField("Find in page", text: $query)
                    .focused($isFocused)
                    .font(.system(size: 15))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: query) { newValue in
                        tab?.findInPage(newValue)
                    }

                if !query.isEmpty {
                    Button(action: { query = ""; tab?.clearFindInPage() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Button("Done") {
                tab?.clearFindInPage()
                query = ""
                AppState.shared.isShowingFindInPage = false
            }
            .font(.system(size: 15, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).shadow(color: .black.opacity(0.1), radius: 2, y: 2))
        .onAppear { isFocused = true }
    }
}

// MARK: - Error Overlay
struct ErrorOverlayView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                let lines = message.split(separator: "\n", maxSplits: 1)
                Text(String(lines.first ?? ""))
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)

                if lines.count > 1 {
                    Text(String(lines[1]))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button(action: retryAction) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(25)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground).opacity(0.95))
    }
}
