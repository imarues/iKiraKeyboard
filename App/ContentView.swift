import SwiftUI
import Photos
import Translation

struct ContentView: View {
    @State private var photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    setupCard
                    photoCard
                    TranslationSetupView()
                    privacyCard
                }
                .padding(18)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("iKira Keyboard")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Arabic + English")
                .font(.title2.bold())
            Text("كيبورد عربي/إنكليزي مع حافظة متعددة، لقطات شاشة حديثة، ترجمة فورية، إيموجي واقتراحات كلمات.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var setupCard: some View {
        card {
            Label("تفعيل الكيبورد", systemImage: "keyboard")
                .font(.headline)
            Text("الإعدادات ← عام ← لوحة المفاتيح ← لوحات المفاتيح ← إضافة لوحة مفاتيح جديدة ← iKira Keyboard")
            Text("بعدها فعّل Allow Full Access حتى تعمل الحافظة والترجمة والميزات المشتركة.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var photoCard: some View {
        card {
            Label("لقطات الشاشة — آخر 30 دقيقة", systemImage: "camera")
                .font(.headline)
            Text(photoPermissionText)
                .foregroundStyle(.secondary)
            Button("منح صلاحية الصور") {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.async { photoStatus = status }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var photoPermissionText: String {
        switch photoStatus {
        case .authorized: return "مفعّلة. زر الكاميرا في الكيبورد يعرض Screenshots التي التُقطت خلال آخر نصف ساعة فقط."
        case .limited: return "الصلاحية محدودة؛ قد لا تظهر كل لقطات الشاشة."
        case .denied, .restricted: return "صلاحية الصور غير متاحة. يمكنك تغييرها من إعدادات التطبيق."
        default: return "نحتاج صلاحية الصور لعرض لقطات الشاشة الحديثة داخل الكيبورد."
        }
    }

    private var privacyCard: some View {
        card {
            Label("الخصوصية", systemImage: "hand.raised")
                .font(.headline)
            Text("قائمة لقطات الشاشة لا تنشئ نسخاً إضافية من الصور: يتم عرض الأصول الموجودة في Photos لمدة 30 دقيقة فقط. محفوظات النصوص تبقى محلياً في App Group على جهازك.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}
