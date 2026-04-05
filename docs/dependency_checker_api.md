# Framework Diagnostic Tool

This engine provides a robust way to check for development tools on Windows systems using `Process.run`.

## Core Classes

### `DependencyResult`
The structured output for every dependency check.

| Property | Type | Description |
| :--- | :--- | :--- |
| `name` | `String` | The display name of the dependency. |
| `isInstalled` | `bool` | `true` if the command executed successfully and returned valid output. |
| `version` | `String` | The parsed version string (empty if not installed). |
| `rawOutput` | `String` | The full unmodified output from the command line. |
| `error` | `String?` | The error message or exception trace if the check failed. |

---

## Public Methods

### `checkDependency(String name)`
Dispatches a check for a single dependency by name.

**Supported Names:**
`node.js`, `npm`, `php`, `composer`, `.net sdk`, `python`, `flask`, `quasar cli`, `electron`, `cordova`, `gradle`, `java`, `adb`.

```dart
final checker = DependencyChecker();
final result = await checker.checkDependency('Node.js');

if (result.isInstalled) {
  print('Found ${result.name} version ${result.version}');
} else {
  print('Error: ${result.error}');
}
```

### `checkAll(List<String> dependencies)`
Runs multiple checks in parallel using `Future.wait`.

```dart
final checker = DependencyChecker();
final results = await checker.checkAll(['PHP', 'Composer', 'Java']);

for (var res in results) {
  print('${res.name}: ${res.isInstalled ? 'Installed (${res.version})' : 'Missing'}');
}
```

---

## Integration Example (Provider/State Management)

If you are using a state management solution, you can easily wrap the checker:

```dart
class DependencyProvider extends ChangeNotifier {
  final DependencyChecker _checker = DependencyChecker();
  List<DependencyResult> results = [];
  bool isLoading = false;

  Future<void> fetchStatus() async {
    isLoading = true;
    notifyListeners();
    
    results = await _checker.checkAll(['Node.js', 'NPM', 'Python']);
    
    isLoading = false;
    notifyListeners();
  }
}
```

## Adding New Dependencies
To extend the checker:
1. Add a case to the `switch` statement in `checkDependency`.
2. Implement a private `_checkSpecificTool()` method using the `_execute` helper.
3. Provide a regex or string manipulation logic to parse the version from `stdout`/`stderr`.
