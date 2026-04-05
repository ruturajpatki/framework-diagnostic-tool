/**
 * Project Name: Framework Diagnostic Tool
 * Purpose: Main user interface for displaying and triggering dependency checks.
 * Author: Ruturaj Patki
 */

import 'package:flutter/material.dart';

import '../models/dependency_result.dart';
import '../models/windows_system_info.dart';
import '../services/dependency_checker.dart';
import '../services/windows_system_info_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, List<String>> _groups = {
    'JavaScript Toolchain': ['Node.js', 'NPM', 'Quasar CLI', 'Electron'],
    'PHP / Laravel': ['PHP', 'Composer'],
    '.NET': ['.NET SDK'],
    'Python / Flask': ['Python', 'Flask'],
    'Mobile (Android)': ['Java', 'ADB', 'Gradle', 'Cordova'],
  };

  final Map<String, DependencyResult?> _results = {};
  WindowsSystemInfo? _sysInfo;
  bool _isLoading = false;

  void _checkDependencies() async {
    setState(() {
      _isLoading = true;
      _results.clear();
      _sysInfo = null;
    });

    final checker = DependencyChecker();
    final sysInfoService = WindowsSystemInfoService();
    final allDeps = _groups.values.expand((element) => element).toList();

    // Fire off all futures and update state dynamically when each returns.
    final sysInfoFuture = sysInfoService.getSystemInfo().then((info) {
      if (mounted) {
        setState(() {
          _sysInfo = info;
        });
      }
    }).catchError((_) {});

    final futures = allDeps.map((dep) {
      return checker.checkDependency(dep).then((res) {
        if (mounted) {
          setState(() {
            _results[dep] = res;
          });
        }
        return res;
      });
    });

    // Support batch execution using Future.wait
    await Future.wait([sysInfoFuture, ...futures]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Framework Diagnostic Tool'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkDependencies,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Dependencies'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSysInfoCard(),
          ..._groups.keys.map((groupName) {
            final deps = _groups[groupName]!;
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 2,
              child: ExpansionTile(
                initiallyExpanded: true,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  groupName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                children: deps.map((dep) => _buildDependencyRow(dep)).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDependencyRow(String name) {
    final result = _results[name];

    return ListTile(
      leading: _buildStatusIcon(result),
      title: Text(name),
      subtitle: result == null
          ? const Text('Pending...')
          : result.isInstalled
              ? Text('Version: ${result.version}')
              : Text(result.error ?? 'Not installed', style: const TextStyle(color: Colors.red)),
      trailing: result == null
          ? const SizedBox.shrink()
          : IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'View Raw Output',
              onPressed: () => _showRawOutputDialog(result),
            ),
    );
  }

  Widget _buildStatusIcon(DependencyResult? result) {
    if (result == null) {
      if (_isLoading) {
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return const Icon(Icons.help_outline, color: Colors.grey);
    }

    if (result.isInstalled) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else {
      return const Icon(Icons.cancel, color: Colors.red);
    }
  }

  void _showRawOutputDialog(DependencyResult result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${result.name} - Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!result.isInstalled && result.error != null) ...[
                  const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.withValues(alpha: 0.1),
                    width: double.infinity,
                    child: Text(result.error!),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Raw Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: double.infinity,
                  child: Text(
                    result.rawOutput.isEmpty ? '<Empty Output>' : result.rawOutput,
                    style: const TextStyle(fontFamily: 'Consolas'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSysInfoCard() {
    final computerName = _sysInfo?.computerName ?? 'Unknown';
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          'System Info - $computerName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCompactSysInfoItem('OS Name', _sysInfo?.osName, _sysInfo?.osName != 'Unknown Windows')),
                    Expanded(child: _buildCompactSysInfoItem('OS Version', _sysInfo != null ? '${_sysInfo!.osVersion}' : null, _sysInfo?.osVersion != 'Unknown')),
                    Expanded(child: _buildCompactSysInfoItem('RAM', _sysInfo != null ? '${_sysInfo!.totalRamGB} GB' : null, (_sysInfo?.totalRamGB ?? 0) > 0)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCompactSysInfoItem('CPU', _sysInfo?.cpuModel, _sysInfo?.cpuModel != 'Unknown CPU')),
                    Expanded(child: _buildCompactSysInfoItem('Architecture', _sysInfo != null ? (_sysInfo!.is64Bit ? '64-bit' : '32-bit') : null, true)),
                    Expanded(child: _buildCompactSysInfoItem('Cores', _sysInfo != null ? '${_sysInfo!.numberOfCores}' : null, (_sysInfo?.numberOfCores ?? 0) > 0)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSysInfoItem(String title, String? value, bool isSuccess) {
    Widget icon;
    if (_sysInfo == null) {
      if (_isLoading) {
        icon = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      } else {
        icon = const Icon(Icons.help_outline, color: Colors.grey, size: 16);
      }
    } else if (isSuccess) {
      icon = const Icon(Icons.check_circle, color: Colors.green, size: 16);
    } else {
      icon = const Icon(Icons.cancel, color: Colors.red, size: 16);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _sysInfo == null ? 'Pending...' : (value ?? 'N/A'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _sysInfo != null && !isSuccess ? Colors.red : null,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
