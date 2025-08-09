# 🚀 Universal Flutter Lite Application Rules

## 🎯 PRIMARY GOAL: Keep APK under 12MB while maintaining core functionality

**Golden Rule: Every dependency must justify its existence with significant user value.**

## 📐 Project Structure Standards

### File Organization
- Maximum 150 lines per file for optimal tree-shaking
- Feature-based modular structure to prevent unused code inclusion
- Shared services and models to eliminate code duplication
- Clear separation of concerns for easier dead code elimination
- Replace default Flutter app icons and splash screens with compressed, branded assets (budget: max 200KB total)

### Naming Conventions
- Use descriptive, consistent naming across all projects
- Follow Dart naming conventions strictly
- Keep class and method names concise but clear

## 🔧 State Management Strategy

**Standard Choice: setState + Services Pattern (Zero Dependencies)**
- No third-party state management packages (Provider, BLoC, Riverpod, GetX)
- Use StatefulWidget with setState for UI updates
- Create service classes for business logic and data fetching
- Keep state management simple and predictable

## 🔥 Dependency Management Rules

### Essential Dependencies Only
- Firebase Core, Auth, Firestore (if backend needed)
- SQLite + Path (if offline functionality required)
- HTTP client (only if Firebase Functions cannot replace)

### Forbidden Dependencies
- Any state management packages beyond Flutter's built-in options
- Heavy UI component libraries
- Multiple image handling packages
- Unused or "nice-to-have" packages

### Before Adding ANY Dependency
1. Does this significantly improve core user experience?
2. What's the exact size impact? (Document it)
3. Can existing Flutter widgets achieve 80% of this functionality?
4. Is there a lighter alternative?

## 🎨 UI/UX Standards

### Widget Strategy
- Use Material Design 3 components exclusively
- Stick to basic Material widgets: Container, Column, Row, Text, ElevatedButton, TextField, ListView, Card
- Avoid complex animations, custom painters, and heavy widgets
- Reuse widgets across screens for consistency and size optimization

### Asset Management
- No custom fonts unless absolutely critical for branding (use system fonts)

- Use Material Icons exclusively for standard UI icons
- All images must be compressed to WebP format
- Remove unused assets before every build
- Maximum 1MB total asset budget per application
- Reserve SVG only for complex custom icons or brand assets where Material Icons don't exist
- Never use SVG for simple icons that Material Icons already provides

## ⚡ Performance Standards

### Build Configuration
- Always use release builds for size testing
- Enable tree-shaking for icons
- Use split-per-ABI builds for production
- Enable code obfuscation for production builds
0 Enable tree-shaking in all builds: flutter build apk --tree-shake-icons

### Memory Management
- Dispose controllers and streams properly
- Use ListView.builder for long lists
- Cache only essential data
- Implement proper loading states

## 🗄️ Data Strategy

### Local Storage
- Use SharedPreferences for simple key-value storage
- SQLite only when offline functionality is critical
- Implement smart cache management with auto-cleanup
- Avoid storing large data structures in memory

### Firebase Optimization
- Use minimal Firebase imports
- Optimize Firestore queries for cost and performance
- Implement pagination for large datasets
- Cache frequently accessed data locally

## 📏 Size Monitoring Process

### Regular Size Checks
- Check APK size after every major feature addition
- Document size impact of each new dependency
- Use flutter build apk --analyze-size for detailed breakdowns

### Size Budgets
- Flutter Engine: ~4-5MB (fixed cost)
For Simple Apps (8-12MB target):

- Flutter Engine: ~4-5MB (fixed)
- Firebase (Core + Auth + Firestore): ~4-6MB
- SharedPreferences + essential packages: ~500KB
- App Code (realistic): ~2-4MB
- Assets (compressed): ~1-2MB
- Total: 12-18MB ✅ Achievable

For Feature-Rich Apps (15-20MB target):

- Flutter Engine: ~4-5MB (fixed)
- Firebase + essential packages: ~5-7MB
- SQLite (if offline needed): ~1-2MB
- App Code (multiple features): ~4-8MB
- Assets: ~2-3MB
- Total: 16-25MB ✅ Realistic for quality apps

## 🚨 Development Constraints

### Code Quality
- No dead code or unused imports
- Regular code reviews focusing on size impact
- Use const constructors wherever possible
- Minimize widget rebuilds with proper key usage

### Testing Requirements
- Test on low-end devices regularly
- Monitor startup time (target: under 3 seconds)
- Test offline functionality if applicable
- Verify smooth 60fps performance

## ✅ Success Criteria

### Technical Metrics
- APK size under 12MB for initial download
- App startup time under 3 seconds
- Smooth performance on devices with 2GB RAM
- No memory leaks or excessive battery drain

### User Experience
- Core functionality works flawlessly
- Intuitive navigation and interactions
- Fast response times for all user actions
- Graceful handling of network issues

## 🔄 Optimization Workflow

### Development Phase
1. Build features with basic Flutter widgets first
2. Optimize only after core functionality is complete
3. Regular size audits during development
4. Document all dependency additions with justification

### Pre-Release Phase
1. Full size analysis and optimization
2. Remove unused code and assets
3. Test on variety of devices and network conditions
4. Performance profiling and optimization

### Maintenance Phase
1. Regular dependency audits and updates
2. Monitor app size with each update
3. User feedback analysis for feature prioritization
4. Continuous performance monitoring

## 🎪 Exception Handling

### When to Break Rules
- Critical user experience features that require specific dependencies
- Platform-specific requirements that need specialized packages
- Security requirements that mandate certain implementations

### Documentation Requirements
- Document all rule exceptions with detailed justification
- Include size impact analysis for exceptions
- Set review timeline for reconsidering exceptions
- Alternative solution exploration for future versions

---

**Remember: Simple, fast, and lightweight applications provide better user experiences than feature-heavy, slow applications.**