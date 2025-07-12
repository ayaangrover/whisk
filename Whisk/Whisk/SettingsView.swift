import SwiftUI

struct SettingsView: View {
    @Binding var isSignedIn: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    Button("Log Out", role: .destructive) {
                        self.isSignedIn = false
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isSignedIn: .constant(true))
    }
}
