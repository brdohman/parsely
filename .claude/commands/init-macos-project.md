---
disable-model-invocation: true
description: Initialize a new macOS Swift/SwiftUI project with standard structure and development tooling
argument-hint: project name (e.g., "MyAwesomeApp")
---

# /init-macos-project

Create a new macOS Swift/SwiftUI project from scratch with standard project structure.

## Overview

This command creates a complete macOS application project including:
- Xcode project with SwiftUI lifecycle
- MVVM folder structure (Views, ViewModels, Models, Services)
- SwiftLint configuration for code quality
- Git repository with proper .gitignore
- Optional Core Data stack

## What It Creates

All app code is created inside the `app/` directory:

```
app/
├── [AppName].xcodeproj/
├── [AppName]/
│   ├── App/
│   │   └── [AppName]App.swift
│   ├── Models/
│   │   └── [AppName].xcdatamodeld  (if Core Data)
│   ├── Views/
│   │   ├── ContentView.swift
│   │   └── Components/
│   ├── ViewModels/
│   ├── Services/
│   ├── Utilities/
│   └── Resources/
│       └── Assets.xcassets
├── [AppName]Tests/
├── [AppName]UITests/
├── .swiftlint.yml
├── .gitignore
└── README.md
```

## Prerequisites

Before running `/init-macos-project`, ensure these tools are installed:
- Xcode 15+ (`xcode-select --install` for command line tools)
- Swift 5.9+ (bundled with Xcode 15+)
- Git
- SwiftLint (optional but recommended: `brew install swiftlint`)

Check with:
```bash
xcodebuild -version && swift --version && git --version
```

## Usage

```
/init-macos-project MyAwesomeApp
/init-macos-project MyAwesomeApp --with-core-data
```

## Flow

### Phase 1: Discovery

Ask these questions to understand the project:

1. **Project name** - From argument or prompt:
   ```
   What is the project name? [argument or prompt]
   ```
   Note: Project name should be PascalCase (e.g., MyAwesomeApp)

2. **Core Data**:
   ```
   Include Core Data for local persistence? [y/N]
   ```

3. **Minimum macOS version**:
   ```
   Minimum macOS version: [26.0] (default) - macOS Tahoe
   ```

### Phase 2: Create Xcode Project

Create the Xcode project inside the `app/` directory:

1. Create app directory and project directory:
   ```bash
   mkdir -p app
   cd app
   mkdir -p [AppName]
   ```

2. Generate Xcode project structure:
   ```bash
   # Create the main app target directory (inside app/)
   mkdir -p [AppName]/App
   mkdir -p [AppName]/Models
   mkdir -p [AppName]/Views/Components
   mkdir -p [AppName]/ViewModels
   mkdir -p [AppName]/Services
   mkdir -p [AppName]/Utilities
   mkdir -p [AppName]/Resources

   # Create test target directories
   mkdir -p [AppName]Tests
   mkdir -p [AppName]UITests
   ```

3. Create the main app file `app/[AppName]/App/[AppName]App.swift`:
   ```swift
   import SwiftUI

   @main
   struct [AppName]App: App {
       var body: some Scene {
           WindowGroup {
               ContentView()
           }
       }
   }
   ```

4. Create `[AppName]/Views/ContentView.swift`:
   ```swift
   import SwiftUI

   struct ContentView: View {
       var body: some View {
           VStack {
               Image(systemName: "globe")
                   .imageScale(.large)
                   .foregroundStyle(.tint)
               Text("Hello, world!")
           }
           .padding()
       }
   }

   #Preview {
       ContentView()
   }
   ```

5. Create Assets.xcassets:
   ```bash
   mkdir -p [AppName]/Resources/Assets.xcassets/AppIcon.appiconset
   mkdir -p [AppName]/Resources/Assets.xcassets/AccentColor.colorset
   ```

6. Create Package.swift or generate .xcodeproj using swift package tools or xcodegen if available.

### Phase 3: Configure Project

1. Add SwiftLint configuration `.swiftlint.yml`:
   ```yaml
   disabled_rules:
     - trailing_whitespace
     - line_length

   opt_in_rules:
     - empty_count
     - force_unwrapping
     - implicit_return
     - modifier_order

   excluded:
     - .build
     - DerivedData
     - Pods

   line_length:
     warning: 120
     error: 200

   type_body_length:
     warning: 300
     error: 500

   file_length:
     warning: 500
     error: 1000

   identifier_name:
     min_length: 2
     max_length: 50
   ```

2. Add `.gitignore`:
   ```gitignore
   # Xcode
   DerivedData/
   build/
   *.xcodeproj/xcuserdata/
   *.xcodeproj/project.xcworkspace/xcuserdata/
   *.xcworkspace/xcuserdata/

   # Swift Package Manager
   .build/
   .swiftpm/
   Package.resolved

   # CocoaPods (if used)
   Pods/
   Podfile.lock

   # Carthage (if used)
   Carthage/Build/
   Carthage/Checkouts/

   # Fastlane
   fastlane/report.xml
   fastlane/Preview.html
   fastlane/screenshots/**/*.png
   fastlane/test_output/

   # macOS
   .DS_Store
   *.swp
   *~

   # Secrets and local config
   *.xcconfig
   !Shared.xcconfig
   Secrets.swift

   # Archives
   *.xcarchive

   # Playgrounds
   timeline.xctimeline
   playground.xcworkspace

   # Instruments
   *.trace
   ```

3. Create `README.md`:
   ```markdown
   # [AppName]

   A macOS application built with SwiftUI.

   ## Requirements

   - macOS 26.0+ (Tahoe)
   - Xcode 16+
   - Swift 6.0+

   ## Setup

   1. Open `app/[AppName].xcodeproj` in Xcode
   2. Select your development team in Signing & Capabilities
   3. Build and run (Cmd+R)

   ## Project Structure

   - `App/` - Application entry point
   - `Models/` - Data models and Core Data entities
   - `Views/` - SwiftUI views
   - `ViewModels/` - View models (MVVM pattern)
   - `Services/` - Business logic and API services
   - `Utilities/` - Helper functions and extensions
   - `Resources/` - Assets, localization, and other resources

   ## Architecture

   This project follows the MVVM (Model-View-ViewModel) architecture pattern.
   ```

### Phase 4: Core Data Setup (if selected)

If `--with-core-data` flag is provided:

1. Create Core Data model `[AppName]/Models/[AppName].xcdatamodeld`

2. Create `[AppName]/Services/PersistenceController.swift`:
   ```swift
   import CoreData

   struct PersistenceController {
       static let shared = PersistenceController()

       let container: NSPersistentContainer

       init(inMemory: Bool = false) {
           container = NSPersistentContainer(name: "[AppName]")

           if inMemory {
               container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
           }

           container.loadPersistentStores { _, error in
               if let error = error as NSError? {
                   fatalError("Unresolved error \(error), \(error.userInfo)")
               }
           }

           container.viewContext.automaticallyMergesChangesFromParent = true
       }

       static var preview: PersistenceController = {
           let controller = PersistenceController(inMemory: true)
           // Add preview data here
           return controller
       }()
   }
   ```

3. Update `[AppName]App.swift` to inject Core Data context:
   ```swift
   import SwiftUI

   @main
   struct [AppName]App: App {
       let persistenceController = PersistenceController.shared

       var body: some Scene {
           WindowGroup {
               ContentView()
                   .environment(\.managedObjectContext, persistenceController.container.viewContext)
           }
       }
   }
   ```

### Phase 5: Initialize Git

1. Initialize git repository:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: [AppName] macOS app scaffold"
   ```

### Phase 6: Handoff

Display summary:

```
=== Project Initialized ===

Project: [AppName]
Location: [full path]
Type: macOS SwiftUI Application

Structure created:
  [checkmark] App entry point
  [checkmark] MVVM folder structure
  [checkmark] SwiftLint configuration
  [checkmark] Git repository initialized
  [checkmark] Core Data stack (if selected)

Next steps:
  1. Open app/[AppName].xcodeproj in Xcode
  2. Select your development team
  3. Build and run (Cmd+R)
  4. /feature "Add first feature"
```

## Error Handling

If any step fails:

1. **Log the error with context**:
   ```
   [ERROR] Failed to create Xcode project
   Output: [error details]
   ```

2. **Show what completed successfully**:
   ```
   Completed:
     [checkmark] Project directory created
     [checkmark] Folder structure created

   Failed:
     [x] Xcode project generation

   Not started:
     [ ] SwiftLint configuration
     [ ] Git initialization
   ```

3. **Offer to retry or rollback**:
   ```
   Would you like to:
   [1] Retry failed step
   [2] Clean up and start over
   [3] Continue manually
   ```

## Example Session

```
User: /init-macos-project MyAwesomeApp

Claude: Initializing macOS project: MyAwesomeApp

Include Core Data for local persistence? [y/N]

User: n

Claude: Minimum macOS version: [14.0]

User: [enter to accept default]

Claude: Creating project structure...
  Creating App/...
  Creating Views/...
  Creating ViewModels/...
  Creating Models/...
  Creating Services/...
  Creating Utilities/...
  Creating Resources/...

Adding SwiftLint configuration...
Adding .gitignore...
Creating README.md...

Initializing git repository...
Creating initial commit...

=== Project Initialized ===

Project: MyAwesomeApp
Location: /Users/dev/projects/MyAwesomeApp
Type: macOS SwiftUI Application

Structure created:
  [checkmark] App entry point
  [checkmark] MVVM folder structure
  [checkmark] SwiftLint configuration
  [checkmark] Git repository initialized

Next steps:
  1. Open MyAwesomeApp.xcodeproj in Xcode
  2. Select your development team
  3. Build and run (Cmd+R)
  4. /feature "Add first feature"
```

## Notes

- Project names should be PascalCase without spaces or special characters
- The generated project targets macOS 26.0+ (Tahoe) by default
- SwiftLint is configured but requires installation (`brew install swiftlint`)
- For more complex project generation, consider using tools like XcodeGen or Tuist
