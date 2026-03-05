import SwiftUI
import FoundationModels

@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var inputText = ""
    var isLoading = false
    var selectedImage: UIImage?
    var errorMessage: String?

    private var session: LanguageModelSession

    init() {
        session = LanguageModelSession(
            instructions: """
            You are an expert Apple device troubleshooting assistant. You help diagnose and fix \
            issues with Mac, iPhone, iPad, Apple Watch, and other Apple products.

            When the user describes a problem or shares text extracted from a screenshot, you should:
            1. Identify the likely cause of the issue
            2. Provide clear, step-by-step troubleshooting instructions
            3. Suggest when to contact Apple Support if the issue is hardware-related
            4. Reference specific macOS/iOS settings paths when applicable (e.g., System Settings > General > Software Update)

            Keep responses concise and actionable. Use numbered steps for instructions. \
            If you need more information to diagnose the issue, ask specific follow-up questions.
            """
        )
    }

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = selectedImage

        guard !text.isEmpty || image != nil else { return }

        inputText = ""
        selectedImage = nil
        errorMessage = nil

        var prompt = text
        var userDisplayText = text

        if let image {
            let extractedText = await ImageTextExtractor.extractText(from: image)
            if !extractedText.isEmpty {
                let imageContext = "\n\n[Text extracted from screenshot]\n\(extractedText)"
                prompt += imageContext
                if userDisplayText.isEmpty {
                    userDisplayText = "Sent a photo for troubleshooting"
                }
            } else if userDisplayText.isEmpty {
                userDisplayText = "Sent a photo (no text could be extracted)"
            }
        }

        let userMessage = Message(role: .user, text: userDisplayText, image: image)
        messages.append(userMessage)

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await session.respond(to: prompt)
            let assistantMessage = Message(role: .assistant, text: response.content)
            messages.append(assistantMessage)
        } catch {
            errorMessage = "Failed to get response: \(error.localizedDescription)"
            let errorMsg = Message(
                role: .assistant,
                text: "Sorry, I couldn't process that request. Please try again."
            )
            messages.append(errorMsg)
        }
    }

    func clearChat() {
        messages.removeAll()
        session = LanguageModelSession(
            instructions: """
            You are an expert Apple device troubleshooting assistant. You help diagnose and fix \
            issues with Mac, iPhone, iPad, Apple Watch, and other Apple products.

            When the user describes a problem or shares text extracted from a screenshot, you should:
            1. Identify the likely cause of the issue
            2. Provide clear, step-by-step troubleshooting instructions
            3. Suggest when to contact Apple Support if the issue is hardware-related
            4. Reference specific macOS/iOS settings paths when applicable (e.g., System Settings > General > Software Update)

            Keep responses concise and actionable. Use numbered steps for instructions. \
            If you need more information to diagnose the issue, ask specific follow-up questions.
            """
        )
        errorMessage = nil
    }
}
