---
paths:
  - "app/**/*.xcdatamodeld/**"
  - "app/**/Persistence/**/*.swift"
  - "app/**/Models/**/*.swift"
---

# Core Data Migration Standards

## Model Versioning

1. ALWAYS create new model version for schema changes
2. Use lightweight migration when possible
3. Document breaking changes

## Migration Types

| Change | Migration Type |
|--------|----------------|
| Add optional attribute | Lightweight |
| Add entity | Lightweight |
| Add relationship | Lightweight |
| Rename attribute | Mapping model |
| Change attribute type | Mapping model |
| Complex data transformation | Custom migration |
| Remove entity | Lightweight (careful!) |

## Lightweight Migration

Automatic when:
- Adding entities
- Adding optional attributes
- Adding relationships with optional inverse
- Renaming with renaming identifier

```swift
// Enable in container setup
let description = NSPersistentStoreDescription()
description.shouldMigrateStoreAutomatically = true
description.shouldInferMappingModelAutomatically = true
```

## Heavyweight Migration

Required when:
- Changing attribute types
- Splitting/merging entities
- Complex data transformations

Steps:
1. Create new model version
2. Create mapping model (.xcmappingmodel)
3. Define entity mappings
4. Test thoroughly

## Testing Migrations

- Test fresh install path
- Test upgrade path with real data samples
- Keep test fixtures in `Tests/Fixtures/`
- Test rollback scenario (if applicable)

## After Schema Changes

1. Create new model version
2. Set new version as current
3. Test migration locally
4. Update any affected fetch requests
5. Document changes in PR

## Never

- Modify existing model version in production
- Skip testing upgrade paths
- Delete attributes without migration plan
- Change attribute types without mapping model
