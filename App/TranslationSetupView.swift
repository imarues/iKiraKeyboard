import SwiftUI
import Translation

struct TranslationSetupView: View {
    @State private var configuration: TranslationSession.Configuration?
    @State private var status = "اضغط تجهيز حتى يسمح iOS بتنزيل حزمة العربية/الإنكليزية عند الحاجة."
    @State private var preparing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("الترجمة الفورية", systemImage: "character.bubble")
                .font(.headline)
            Text(status)
                .foregroundStyle(.secondary)
            Button(preparing ? "جارِ التجهيز…" : "تجهيز AR ⇄ EN") {
                preparing = true
                status = "جارِ فحص/تنزيل حزمة الترجمة…"
                configuration = .init(
                    source: Locale.Language(identifier: "ar"),
                    target: Locale.Language(identifier: "en")
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(preparing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .translationTask(configuration) { session in
            do {
                try await session.prepareTranslation()
                await MainActor.run {
                    preparing = false
                    status = "جاهزة. الضغط المطول على Return يترجم آخر رسالة AR ⇄ EN ويضع الترجمة تحتها."
                }
            } catch {
                await MainActor.run {
                    preparing = false
                    status = "تعذر تجهيز الترجمة: \(error.localizedDescription)"
                }
            }
        }
    }
}
