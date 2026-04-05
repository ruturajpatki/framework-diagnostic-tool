# Windows System Info Service API

The `WindowsSystemInfoService` provides a production-ready way to asynchronously collect and expose Windows OS and system-level information.

## Overview

- **Target Platform**: Windows Desktop ONLY.
- **Dependencies**: `win32`, `device_info_plus`, `ffi`, `dart:io`.
- **Architecture**: Standalone Dart side (no UI/BuildContext dependency).

## Data Model

The service returns a `WindowsSystemInfo` object:

```dart
class WindowsSystemInfo {
  final String osName;        // e.g., Windows 11 Pro
  final String osVersion;     // e.g., 10.0.22631
  final String buildNumber;   // e.g., 22631
  final String cpuModel;      // Full processor name
  final int totalRamGB;       // Total Physical RAM in GB
  final int numberOfCores;    // Logical processor count
  final bool is64Bit;         // true if 64-bit OS
  final String computerName;  // NetBIOS/DNS Name
}
```

## Usage Guide

### 1. Initialization

Import the service and model:

```dart
import 'package:your_app/services/windows_system_info_service.dart';
import 'package:your_app/models/windows_system_info.dart';
```

### 2. Fetching System Info

Always call within an `async` block. It is designed to be non-blocking.

```dart
final service = WindowsSystemInfoService();

try {
  WindowsSystemInfo info = await service.getSystemInfo();
  print('Running on: ${info.osName}');
  print('CPU: ${info.cpuModel}');
} catch (e) {
  print('Error fetching system info: $e');
}
```

### 3. Implementation Details

- **OS Name & CPU**: Fetched via PowerShell queries (`Get-CimInstance`).
- **RAM**: Retrieved using Win32 API `GlobalMemoryStatusEx` for high accuracy.
- **Version/Cores**: Accessed via `device_info_plus`.
- **Safety**: Methods include internal try/catch blocks and return fallback values (e.g., "Unknown") rather than null or crashing.

## Constraints

- Calling `getSystemInfo()` on non-Windows platforms will throw an `UnsupportedError`.
- Ensure your `pubspec.yaml` includes the required dependencies:
  ```yaml
  dependencies:
    win32: ^5.0.0
    device_info_plus: ^10.0.0
    ffi: ^2.1.0
  ```
