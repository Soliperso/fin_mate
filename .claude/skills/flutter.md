# Flutter Development Skill

This skill provides specialized assistance for Flutter development tasks in the FinMate app.

## Capabilities

When this skill is active, I will help you with:

### 1. Feature Scaffolding
Create new features following the clean architecture pattern used in FinMate:

```
lib/features/{feature_name}/
├── data/
│   ├── datasources/
│   │   └── {feature}_remote_datasource.dart
│   ├── models/
│   │   └── {feature}_model.dart
│   └── repositories/
│       └── {feature}_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── {feature}_entity.dart
│   └── repositories/
│       └── {feature}_repository.dart
└── presentation/
    ├── pages/
    │   └── {feature}_page.dart
    ├── widgets/
    │   └── {feature}_widgets.dart
    └── providers/
        └── {feature}_providers.dart
```

### 2. Database Migrations
- Create properly formatted SQL migration files in `supabase/migrations/`
- Include table creation, indexes, RLS policies, and triggers
- Follow existing migration patterns with timestamp prefixes

### 3. State Management
- Create Riverpod providers following FinMate conventions:
  - `FutureProvider` for async data fetching
  - `StateNotifierProvider` for mutable state
  - `Provider` for dependency injection
- Implement proper provider invalidation after mutations

### 4. Development Workflow
Execute common Flutter commands:
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app
- `flutter test` - Run tests
- `flutter analyze` - Check code quality
- `dart format .` - Format code

### 5. Testing Support
- Create widget tests for UI components
- Create unit tests for business logic
- Mock Supabase calls properly
- Test error handling paths

### 6. Code Quality Checks
Before committing changes, ensure:
- [ ] Code is formatted (`dart format .`)
- [ ] No analysis issues (`flutter analyze`)
- [ ] Tests pass (`flutter test`)
- [ ] No sensitive data in commits
- [ ] RLS policies updated for new tables

## Usage Guidelines

### Creating a New Feature

When asked to create a new feature, I will:

1. **Understand Requirements**: Clarify the feature scope and data needs
2. **Plan Architecture**: Design entities, models, and repositories
3. **Database First**: Create migration if database changes are needed
4. **Implement Layers**:
   - Domain entities (pure Dart classes)
   - Data models with JSON serialization
   - Repository interfaces and implementations
   - Riverpod providers for state management
   - UI pages and widgets
5. **Test**: Create appropriate tests
6. **Integrate**: Update routing and navigation if needed

### Database Migration Pattern

For new tables, I will create migrations with:

```sql
-- Table creation
CREATE TABLE IF NOT EXISTS {table_name} (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- other columns
);

-- Indexes
CREATE INDEX idx_{table}_user ON {table_name}(user_id);
CREATE INDEX idx_{table}_created ON {table_name}(created_at DESC);

-- RLS Policies
ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;

CREATE POLICY "{table}_user_select" ON {table_name}
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "{table}_user_insert" ON {table_name}
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "{table}_user_update" ON {table_name}
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "{table}_user_delete" ON {table_name}
  FOR DELETE USING (auth.uid() = user_id);

-- Triggers
CREATE TRIGGER set_{table}_updated_at
  BEFORE UPDATE ON {table_name}
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### Riverpod Provider Pattern

For new features, I will create providers following this pattern:

```dart
// Repository provider
final {feature}RepositoryProvider = Provider<{Feature}Repository>((ref) {
  return {Feature}RepositoryImpl(
    datasource: {Feature}RemoteDatasource(),
  );
});

// Data provider
final {feature}Provider = FutureProvider<List<{Feature}Entity>>((ref) async {
  final repository = ref.watch({feature}RepositoryProvider);
  return await repository.get{Feature}s();
});

// Operations provider
final {feature}OperationsProvider = StateNotifierProvider<{Feature}OperationsNotifier, AsyncValue<void>>((ref) {
  return {Feature}OperationsNotifier(ref.watch({feature}RepositoryProvider));
});
```

### Widget Structure

For new pages, I will follow the Material 3 design system:

```dart
class {Feature}Page extends ConsumerWidget {
  const {Feature}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch({feature}Provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('{Feature}'),
      ),
      body: data.when(
        data: (items) => _buildContent(items),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate({feature}Provider),
        ),
      ),
    );
  }
}
```

## Security Reminders

When working on features, I will ensure:

- All database operations use RLS policies
- Financial amounts use `DECIMAL(15,2)` type
- Sensitive data never appears in logs or commits
- Authentication checks before sensitive operations
- Input validation on all user-provided data

## Best Practices

- **NO styling changes** without explicit request
- Use existing shared widgets from `lib/shared/widgets/`
- Follow Material 3 design patterns
- Display financial amounts with 2 decimal places
- Implement loading and error states
- Invalidate providers after mutations
- Test error handling paths

## Integration with FinMate

This skill understands:
- The complete feature-first architecture
- Supabase integration patterns
- Riverpod state management conventions
- Material 3 design system usage
- Security and RLS policy requirements
- Testing patterns and requirements

Ask me to help with any Flutter development task, and I'll follow these patterns automatically!
