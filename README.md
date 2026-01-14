# LearnLens 🎓

LearnLens is a premium, minimalist mobile application designed to transform your learning materials into interactive assessments. Using advanced AI, LearnLens processes documents and images to generate customized quiz questions, helping you master any subject with ease.

![LearnLens Banner](https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=2070&auto=format&fit=crop)

## ✨ Features

- **📄 Smart Document Processing**: Upload PDFs, text files, or captured images (OCR) of your study materials.
- **🤖 AI-Powered Question Generation**: Automatically generate multiple-choice and short-answer questions from your documents.
- **🖤 Premium UI**: A sleek, high-contrast Black & White theme designed for focus and clarity.
- **🚀 Instant Interaction**: Optimistic UI updates for a snappy, responsive feel.
- **📊 Progress Tracking**: Keep track of your performance and mastery across different topics.
- **⚡ Fast Navigation**: Seamless transitions with GoRouter and a custom splash screen.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [BLoC](https://pub.dev/packages/flutter_bloc)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage)
- **Icons**: [Material Symbols Outlined](https://fonts.google.com/icons?icon.style=Outlined)
- **Typography**: [Google Fonts (Manrope, Inter)](https://fonts.google.com/specimen/Manrope)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase account and a project configured

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/VaradSinghal/LearnLens.git
   cd learnlens
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.

4. **Run the app**:
   ```bash
   flutter run
   ```

## 🎨 Theme Guidelines

LearnLens uses a custom `AppTheme` for consistency:
- **Background**: Pure Black (#000000)
- **Primary**: Neon Green/White Accents
- **Surface**: Dark Grey/Frosted Glass effects
- **Typography**: Bold, clean Manrope fonts

---

Built with ❤️ by [Varad Singhal](https://github.com/VaradSinghal)
