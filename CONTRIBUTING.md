# Contributing to NEXORA

Thank you for your interest in contributing to **NEXORA**! We welcome bug fixes, improvements, and new feature contributions.

---

## Code of Conduct

Please treat all members of the community with respect and courtesy.

---

## Development Setup

1. **Clone the repository**:
   ```bash
   git clone git@github.com:trydigital2/nexora.git
   cd nexora
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify analyzer**:
   ```bash
   flutter analyze
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

---

## Pull Request Guidelines

1. **Create a branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Follow Conventional Commits**:
   - `feat: add category spending forecasting`
   - `fix: resolve date formatting on weekly chart`
   - `docs: update setup instructions in README`
   - `test: add unit tests for savings goal calculation`

3. **Verify tests and lints**:
   - Ensure `flutter analyze` reports 0 issues.
   - Ensure all tests pass with `flutter test`.
   - Format Dart code with `dart format .`.

4. **Submit your Pull Request**:
   - Clearly describe the changes and motivation.
   - Reference any relevant issues.

Thank you for helping build NEXORA!

