---
paths:
  - "**/Package.swift"
  - "**/Package.resolved"
---

# Dependency Security (Swift Package Manager)

## Before Commit

Review SPM dependencies for security concerns.

## Package.swift Review

When adding new dependencies:
1. Verify source (official repo, not fork)
2. Check for recent maintenance (commits, releases)
3. Review dependency tree (avoid deep nesting)
4. Pin to specific versions or ranges

```swift
// Good - pinned version
.package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")

// Good - exact version for critical deps
.package(url: "https://github.com/Alamofire/Alamofire.git", exact: "5.8.1")

// Avoid - branch tracking
.package(url: "https://github.com/Alamofire/Alamofire.git", branch: "main")
```

## Current Approved Dependencies

- Alamofire (networking)
- Additional deps require review

## If Security Concerns Found

1. Document the issue
2. Create a task for resolution
3. Consider alternatives
4. Block merge if critical

## Never

- Add dependencies from unknown sources
- Use forked repos without justification
- Track `main` branch in production
- Ignore abandoned packages
