import 'package:flutter/material.dart';
import '../models/dependency_result.dart';
import '../services/dependency_checker.dart';

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
  bool _isLoading = false;

  void _checkDependencies() async {
    setState(() {
      _isLoading = true;
      _results.clear();
    });

    final checker = DependencyChecker();
    final allDeps = _groups.values.expand((element) => element).toList();

    // Fire off all futures and update state dynamically when each returns.
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
    await Future.wait(futures);

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
        title: const Text('Dependency Checker'),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _groups.keys.length,
        itemBuilder: (context, index) {
          final groupName = _groups.keys.elementAt(index);
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
        },
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
}
