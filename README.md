# iKira Keyboard

Custom iOS Arabic + English keyboard (iOS 18+) designed around the supplied SwiftKey-style screenshots.

## Implemented MVP

- Exact Arabic/English/numbers/symbols row ordering from the reference screenshots.
- Dark SwiftKey-like theme and bottom row proportions.
- Multi-item clipboard history stored locally in an App Group.
- Clipboard long-press context menu: Pin/Unpin, Move to Beginning, Move to End, Delete.
- Setting for whether newly copied text is inserted at the beginning or end of clipboard history.
- Clipboard monitor while the keyboard is active and Full Access is enabled.
- Camera panel: shows only screenshots created in the last 30 minutes from Photos. Nothing is duplicated or permanently cached.
- Tapping a screenshot copies it to the iOS pasteboard so it can be pasted into the host app.
- Arabic ⇄ English translation using Apple's Translation framework (on-device after language model download).
- Long press Return: translate the current message and append the translation on a new line.
- Translation toolbar button does the same action immediately.
- Emoji panel.
- Local suggestions + supplementary lexicon + learned-word frequency.
- Key press animations and haptics.
- GitHub Actions unsigned IPA build; no local Xcode required.

## Important iOS limitations

1. iOS may show pasteboard privacy prompts. A third-party keyboard cannot silently bypass Apple pasteboard privacy rules.
2. A keyboard extension cannot directly insert an image through `UITextDocumentProxy`; selecting a recent screenshot copies it, then the user uses Paste in the host app.
3. Third-party keyboards do not get direct microphone access. The microphone icon is kept to match the requested layout but reports the iOS limitation when tapped.
4. The host app's own Send button cannot be controlled by a keyboard extension. Long-press translation is attached to this keyboard's Return key.
5. Secure text fields and some phone-pad fields may force iOS back to the system keyboard.

## Build on GitHub

1. Create a new GitHub repository.
2. Upload all files from this project and push to `main`.
3. Open **Actions → Build iKira Keyboard → Run workflow**.
4. Download the `iKiraKeyboard-unsigned` artifact.
5. Sign the IPA with your signing tool/certificate.

### Signing requirements

The app and keyboard extension use App Group:

`group.com.ikira.keyboard`

Your signing setup/provisioning profiles must support the App Group for both bundle identifiers:

- `com.ikira.keyboard`
- `com.ikira.keyboard.KeyboardExtension`

If you change bundle IDs or App Group, update `project.yml` and both entitlement files together.

## First run

1. Open the app and grant Photos access.
2. Tap **Prepare AR ⇄ EN** so iOS can download translation languages if needed.
3. Settings → General → Keyboard → Keyboards → Add New Keyboard → iKira Keyboard.
4. Enable **Allow Full Access**.

## Clipboard behavior

The extension checks `UIPasteboard.general.changeCount` while the keyboard is active. When a new text value appears it is saved in the shared App Group. Duplicate text is moved according to the configured insertion direction instead of creating unlimited duplicate rows.

## Screenshot behavior

The camera panel queries `PHAsset` for images created during the last 30 minutes and filters to `.photoScreenshot`. It refreshes every five seconds while open. It does not copy screenshots into app storage.

## Translation behavior

The extension hosts a tiny SwiftUI `TranslationBridgeView` so iOS 18's `.translationTask` API can provide a `TranslationSession` to the UIKit keyboard extension. Translation content is processed by Apple's Translation framework.
