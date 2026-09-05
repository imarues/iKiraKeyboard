import SwiftUI
import Translation

@MainActor
final class TranslationBridgeModel: ObservableObject {
    struct Request: Equatable {
        let id = UUID()
        let text: String
        let source: KeyboardLanguage
        let target: KeyboardLanguage
        static func == (lhs: Request, rhs: Request) -> Bool { lhs.id == rhs.id }
    }

    @Published var request: Request?
    private var completion: ((Result<String, Error>) -> Void)?

    func translate(_ text: String, source: KeyboardLanguage, target: KeyboardLanguage, completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
        request = Request(text: text, source: source, target: target)
    }

    func finish(_ result: Result<String, Error>, id: UUID) {
        guard request?.id == id else { return }
        completion?(result)
        completion = nil
        request = nil
    }
}

struct TranslationBridgeView: View {
    @ObservedObject var model: TranslationBridgeModel
    @State private var configuration: TranslationSession.Configuration?
    @State private var activeRequestID: UUID?

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onChange(of: model.request) { _, request in
                guard let request else { return }
                activeRequestID = request.id
                configuration = .init(
                    source: Locale.Language(identifier: request.source.rawValue),
                    target: Locale.Language(identifier: request.target.rawValue)
                )
            }
            .translationTask(configuration) { session in
                guard let request = model.request, request.id == activeRequestID else { return }
                do {
                    let response = try await session.translate(request.text)
                    await MainActor.run { model.finish(.success(response.targetText), id: request.id) }
                } catch {
                    await MainActor.run { model.finish(.failure(error), id: request.id) }
                }
            }
    }
}
