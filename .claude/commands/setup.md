---
disable-model-invocation: true
description: Add standard structure to an existing Xcode project without disrupting existing code
argument-hint: [--add-core-data]
---

# /setup

Adds standard structure to an existing Xcode project. Use when you have a macOS Swift project that needs MVVM organization, SwiftLint, or .claude workflow integration.

## Overview

Unlike /init-macos-project which creates a new project, /setup preserves your existing code and adds structure around it.

## When to Use

- Have an existing Xcode project
- Want to add MVVM folder structure
- Want to add SwiftLint configuration
- Want to add .claude workflow integration

## Prerequisites

- Existing .xcodeproj in current directory
- Git initialized
- Xcode 15+ installed

## What It Does

### 1. Creates Folder Structure (if missing)

All app code should be inside `app/`:

```
app/
  [ProjectName]/
    Views/           # SwiftUI views
    ViewModels/      # @Observable view models
    Models/          # Data models and entities
    Services/        # API clients, persistence, business logic
    Utilities/       # Extensions, helpers, constants
    Resources/       # Assets, localization, config files
```

### 2. Adds Configuration Files

- `.swiftlint.yml` - SwiftLint rules (if missing)
- Updates `.gitignore` for Xcode/Swift projects

### 3. Validates Project Setup

- Checks macOS 14.0+ deployment target
- Checks Swift 5.9+ compatibility
- Verifies project structure

## Usage

```
/setup
/setup --add-core-data
```

### Options

- `--add-core-data` - Add Core Data stack with model file

## Flow

### Phase 1: Detection

Scan the project for existing configuration:

- `app/*.xcodeproj` - Xcode project in app/ directory
- `.git/` - Git initialized
- `.swiftlint.yml` - SwiftLint configured
- `Views/`, `ViewModels/` - MVVM structure exists
- `*.xcdatamodeld` - Core Data already configured

### Phase 2: Report

Display what was detected:

```
=== Existing Xcode Project Detected ===

Found:
  [check] MyApp.xcodeproj (Xcode project)
  [check] .git (Git repository)
  [x] .swiftlint.yml (not configured)
  [x] MVVM folders (not structured)

Deployment Target: macOS 14.0
Swift Version: 5.9
```

### Phase 3: Confirmation

Show what will be added:

```
Will add the following structure:

Folders to create:
  - Views/
  - ViewModels/
  - Models/
  - Services/
  - Utilities/
  - Resources/

Files to add:
  - .swiftlint.yml
  - .gitignore updates

Proceed? (y/n)
```

### Phase 4: Execute

Create folders and files:

```bash
# Create folder structure (inside app/[ProjectName]/)
cd app/[ProjectName]
mkdir -p Views ViewModels Models Services Utilities Resources

// Add SwiftLint configuration
// Add .gitignore entries
```

### Phase 5: Summary

```
=== Structure Added ===

Created:
  [check] Views/
  [check] ViewModels/
  [check] Models/
  [check] Services/
  [check] Utilities/
  [check] Resources/
  [check] .swiftlint.yml

Preserved:
  [check] All existing source files unchanged
  [check] Project settings unchanged

Next steps:
  1. Open MyApp.xcodeproj
  2. Drag new folders into Xcode project navigator
  3. Install SwiftLint: brew install swiftlint
  4. Add SwiftLint build phase (see below)
```

## SwiftLint Build Phase

After setup, add this Run Script build phase in Xcode:

```bash
if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, run: brew install swiftlint"
fi
```

## Default .swiftlint.yml

```yaml
disabled_rules:
  - trailing_whitespace
  - line_length

opt_in_rules:
  - empty_count
  - explicit_init
  - closure_spacing
  - overridden_super_call
  - redundant_nil_coalescing
  - private_outlet
  - nimble_operator
  - attributes
  - operator_usage_whitespace
  - closure_end_indentation
  - first_where
  - object_literal
  - number_separator
  - prohibited_super_call
  - fatal_error_message

excluded:
  - Pods
  - .build
  - DerivedData
  - Package.swift

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
  min_length:
    warning: 2
    error: 1
  max_length:
    warning: 50
    error: 60
```

## Preservation Rules

1. **NEVER** overwrite existing files without confirmation
2. **NEVER** modify .xcodeproj programmatically
3. **SKIP** folder creation if folder already exists
4. **WARN** if deployment target is below macOS 14.0

## Does NOT

- Overwrite existing files
- Change project settings without confirmation
- Add Swift Package dependencies (use SPM manually)
- Modify Xcode project file directly

## Core Data Option

When using `--add-core-data`:

Creates:
- `Models/DataModel.xcdatamodeld` template
- `Services/PersistenceController.swift`

```swift
// Services/PersistenceController.swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
```

## Output Format

### Detection Phase
```
Scanning project...

=== Existing Xcode Project Detected ===

Found:
  [check] MyApp.xcodeproj (Xcode project)
  [check] .git (Git repository)
  [x] .swiftlint.yml (not configured)
  [x] MVVM folders (not structured)

Deployment Target: macOS 14.0
Swift Version: 5.9
```

### Execution Phase
```
=== Adding Project Structure ===

[1/3] Creating folder structure...
  - Created Views/
  - Created ViewModels/
  - Created Models/
  - Created Services/
  - Created Utilities/
  - Created Resources/

[2/3] Adding SwiftLint configuration...
  - Created .swiftlint.yml

[3/3] Updating .gitignore...
  - Added Xcode-specific entries
```

### Summary Phase
```
=== Structure Added ===

Created:
  [check] MVVM folder structure (6 folders)
  [check] .swiftlint.yml
  [check] .gitignore updated

Preserved:
  [check] All existing source files unchanged

Next steps:
  1. Open MyApp.xcodeproj in Xcode
  2. Drag new folders into project navigator
  3. Install SwiftLint: brew install swiftlint
  4. Add SwiftLint build phase to target
  5. /feature "Start building"
```
