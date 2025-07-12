import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isSignedIn: Bool

    var body: some View {
        VStack {
            Spacer()
            
            Text("Whisk")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Your Culinary Companion")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.bottom, 50)
            
            Spacer()
            
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                            let userIdentifier = appleIDCredential.user
                            let fullName = appleIDCredential.fullName
                            let email = appleIDCredential.email
                            
                            print("User ID: \(userIdentifier)")
                            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                                print("User Full Name: \(givenName) \(familyName)")
                            }
                            if let email = email {
                                print("User Email: \(email)")
                            }
                            self.isSignedIn = true
                        }
                    case .failure(let error):
                        print("Sign in with Apple failed: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(width: 280, height: 45)
            .padding(.bottom, 20) 
            
            Button {
                self.isSignedIn = true
            } label: {
                Text("Sign In as Guest")
                    .frame(width: 260, height: 45) 
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            .padding(.bottom, 40)
            
            Text("By signing in, you agree to our Terms of Service and Privacy Policy.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isSignedIn: .constant(false))
    }
}
