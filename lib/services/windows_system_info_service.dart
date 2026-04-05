import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:win32/win32.dart';
import '../models/windows_system_info.dart';

class WindowsSystemInfoService {
  Future<WindowsSystemInfo> getSystemInfo() async {
    if (!Platform.isWindows) {
      throw UnsupportedError('WindowsSystemInfoService can only run on Windows Desktop.');
    }

    final osName = await _getOSName();
    final osVersionDetails = await _getOSVersionDetails();
    final cpuModel = await _getCpuModel();
    final totalRamGB = await _getTotalRamGB();
    final is64Bit = await _is64BitOS();

    return WindowsSystemInfo(
      osName: osName,
      osVersion: osVersionDetails['version'] as String,
      buildNumber: osVersionDetails['buildNumber'] as String,
      cpuModel: cpuModel,
      totalRamGB: totalRamGB,
      numberOfCores: osVersionDetails['numberOfCores'] as int,
      is64Bit: is64Bit,
      computerName: osVersionDetails['computerName'] as String,
    );
  }

  Future<String> _getOSName() async {
    try {
      final result = await _runPowerShell('Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption');
      return result.isNotEmpty ? result : 'Unknown Windows';
    } catch (_) {
      return 'Unknown Windows';
    }
  }

  Future<Map<String, dynamic>> _getOSVersionDetails() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      return {
        'version': '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}.${windowsInfo.buildNumber}',
        'buildNumber': windowsInfo.buildNumber.toString(),
        'numberOfCores': windowsInfo.numberOfCores,
        'computerName': windowsInfo.computerName,
      };
    } catch (_) {
      return {
        'version': 'Unknown',
        'buildNumber': 'Unknown',
        'numberOfCores': 0,
        'computerName': Platform.localHostname,
      };
    }
  }

  Future<String> _getCpuModel() async {
    try {
      final result = await _runPowerShell('Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name');
      return result.isNotEmpty ? result : 'Unknown CPU';
    } catch (_) {
      return 'Unknown CPU';
    }
  }

  Future<int> _getTotalRamGB() async {
    try {
      final pointer = calloc<MEMORYSTATUSEX>();
      pointer.ref.dwLength = sizeOf<MEMORYSTATUSEX>();
      final result = GlobalMemoryStatusEx(pointer);
      
      int ramGB = 0;
      if (result != 0) {
        final totalBytes = pointer.ref.ullTotalPhys;
        ramGB = (totalBytes / (1024 * 1024 * 1024)).round();
      }
      free(pointer);
      return ramGB;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _is64BitOS() async {
    try {
      final result = await _runPowerShell('[Environment]::Is64BitOperatingSystem');
      return result.toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<String> _runPowerShell(String command) async {
    try {
      final processResult = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', command],
      );
      if (processResult.exitCode == 0) {
        return processResult.stdout.toString().trim();
      }
      return '';
    } catch (_) {
      return '';
    }
  }
}
