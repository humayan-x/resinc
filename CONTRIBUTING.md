# Contributing to ReSinc

Thank you for your interest in contributing to **ReSinc**! We welcome bug reports, feature suggestions, documentation improvements, and pull requests.

## 🌟 Philosophy & Guiding Principles

1. **Zero Cloud / Privacy First:** ReSinc has no internet permissions in the Android manifest and zero external server dependencies. Any feature that requires network requests or transmitting image data off-device is out of scope.
2. **Predictable Ceilings:** Quality estimation is driven by iterative binary search to guarantee strict file size thresholds without guessing.
3. **Hardware Acceleration:** Native Android platform decoders and compressors are preferred for low battery consumption and rapid processing.

---

## 🛠️ Development Setup

### Prerequisites
- **Flutter SDK:** 3.13+ (stable channel)
- **Dart SDK:** 3.1+
- **Android SDK:** API 24+ (minSdkVersion 24, targetSdkVersion 34)
- **JDK:** 17

### Clone & Run
```bash
git clone https://github.com/humayan-x/resinc.git
cd resinc
flutter pub get
flutter run
```

---

## 🧪 Testing & Quality Checks

Before submitting a Pull Request, ensure that:

1. **Code Analysis Passes Cleanly:**
   ```bash
   flutter analyze
   ```
2. **All Unit and Widget Tests Pass:**
   ```bash
   flutter test
   ```
3. **Format Code:**
   ```bash
   dart format .
   ```

---

## 🚀 Pull Request Workflow

1. Fork the repository and create your feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Write clean, self-documenting code with comments explaining design choices.
3. Add corresponding unit or widget tests in `test/` for any new logic or screens.
4. Ensure all tests pass (`flutter test`).
5. Commit your changes with descriptive commit messages.
6. Push to your fork and submit a Pull Request to `main`.

---

## 🐛 Reporting Issues

- Use the [GitHub Issues](https://github.com/humayan-x/resinc/issues) tracker.
- Include your Android OS version, device model, and steps to reproduce.
- If reporting a compression issue, note the input image format and dimensions.

---

## 📄 License

By contributing to ReSinc, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).
