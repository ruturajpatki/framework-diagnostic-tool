import 'dart:io';
import '../models/dependency_result.dart';

class DependencyChecker {
  Future<List<DependencyResult>> checkAll(List<String> dependencies) async {
    return await Future.wait(dependencies.map((dep) => checkDependency(dep)));
  }

  Future<DependencyResult> checkDependency(String name) async {
    switch (name.toLowerCase()) {
      case 'node.js':
        return await _checkNode();
      case 'npm':
        return await _checkNpm();
      case 'php':
        return await _checkPhp();
      case 'composer':
        return await _checkComposer();
      case '.net sdk':
      case '.net':
        return await _checkDotNet();
      case 'python':
        return await _checkPython();
      case 'flask':
        return await _checkFlask();
      case 'quasar cli':
      case 'quasar':
        return await _checkQuasar();
      case 'electron':
        return await _checkElectron();
      case 'cordova':
        return await _checkCordova();
      case 'gradle':
        return await _checkGradle();
      case 'java':
        return await _checkJava();
      case 'adb':
        return await _checkAdb();
      default:
        return DependencyResult(
          name: name,
          isInstalled: false,
          version: '',
          rawOutput: '',
          error: 'Unknown dependency: $name',
        );
    }
  }

  Future<DependencyResult> _execute(
      String name, String command, String Function(String stdout, String stderr) parseVersion,
      {bool stderrAsValidOutput = false}) async {
    try {
      final result = await Process.run('cmd', ['/c', command]);
      final stdoutStr = result.stdout.toString().trim();
      final stderrStr = result.stderr.toString().trim();

      if (stderrStr.contains('not recognized as an internal or external command')) {
        return DependencyResult(
          name: name,
          isInstalled: false,
          version: '',
          rawOutput: stdoutStr,
          error: '$name is not installed or not in PATH.',
        );
      }

      if (result.exitCode != 0 || (stderrStr.isNotEmpty && !stderrAsValidOutput)) {
        return DependencyResult(
          name: name,
          isInstalled: false,
          version: '',
          rawOutput: stdoutStr,
          error: stderrStr.isNotEmpty ? stderrStr : 'Command failed with exit code ${result.exitCode}',
        );
      }

      if (stdoutStr.isEmpty && !stderrAsValidOutput) {
         return DependencyResult(
          name: name,
          isInstalled: false,
          version: '',
          rawOutput: stdoutStr,
          error: 'Empty output received',
        );
      }

      final version = parseVersion(stdoutStr, stderrStr);
      
      return DependencyResult(
        name: name,
        isInstalled: true,
        version: version,
        rawOutput: stderrAsValidOutput
            ? [if (stdoutStr.isNotEmpty) stdoutStr, if (stderrStr.isNotEmpty) stderrStr].join('\n')
            : stdoutStr,
        error: null,
      );
    } catch (e) {
      return DependencyResult(
        name: name,
        isInstalled: false,
        version: '',
        rawOutput: '',
        error: e.toString(),
      );
    }
  }

  Future<DependencyResult> _checkNode() async {
    return await _execute('Node.js', 'node -v', (stdout, stderr) {
      return stdout.replaceFirst('v', '');
    });
  }

  Future<DependencyResult> _checkNpm() async {
    return await _execute('NPM', 'npm -v', (stdout, stderr) {
      return stdout;
    });
  }

  Future<DependencyResult> _checkPhp() async {
    return await _execute('PHP', 'php -v', (stdout, stderr) {
      final match = RegExp(r'PHP\s+([\d\.]+)').firstMatch(stdout);
      return match != null ? match.group(1) ?? '' : stdout.split(' ').take(2).join(' ');
    });
  }

  Future<DependencyResult> _checkComposer() async {
    return await _execute('Composer', 'composer --version', (stdout, stderr) {
      final textToSearch = '$stdout\n$stderr';
      final match = RegExp(r'Composer version\s+([\d\.]+)').firstMatch(textToSearch);
      return match != null ? match.group(1) ?? '' : '';
    }, stderrAsValidOutput: true);
  }

  Future<DependencyResult> _checkDotNet() async {
    return await _execute('.NET SDK', 'dotnet --version', (stdout, stderr) {
      return stdout;
    });
  }

  Future<DependencyResult> _checkPython() async {
    return await _execute('Python', 'python --version', (stdout, stderr) {
      return stdout.replaceFirst('Python ', '');
    });
  }

  Future<DependencyResult> _checkFlask() async {
    return await _execute('Flask', 'flask --version', (stdout, stderr) {
      final match = RegExp(r'Flask\s+([\d\.]+)').firstMatch(stdout);
      return match != null ? match.group(1) ?? '' : '';
    });
  }

  Future<DependencyResult> _checkQuasar() async {
    return await _execute('Quasar CLI', 'quasar -v', (stdout, stderr) {
      return stdout.split(' ').last.replaceFirst('v', '');
    });
  }

  Future<DependencyResult> _checkElectron() async {
    return await _execute('Electron', 'electron -v', (stdout, stderr) {
      return stdout.replaceFirst('v', '');
    });
  }

  Future<DependencyResult> _checkCordova() async {
    return await _execute('Cordova', 'cordova -v', (stdout, stderr) {
      return stdout;
    });
  }

  Future<DependencyResult> _checkGradle() async {
    return await _execute('Gradle', 'gradle -v', (stdout, stderr) {
      final match = RegExp(r'Gradle\s+([\d\.]+)').firstMatch(stdout);
      return match != null ? match.group(0) ?? '' : '';
    });
  }

  Future<DependencyResult> _checkJava() async {
    return await _execute('Java', 'java -version', (stdout, stderr) {
      // version in stderr
      final match = RegExp(r'version\s+"([^"]+)"').firstMatch(stderr);
      return match != null ? match.group(1) ?? '' : stderr;
    }, stderrAsValidOutput: true);
  }

  Future<DependencyResult> _checkAdb() async {
    return await _execute('ADB', 'adb version', (stdout, stderr) {
      final match = RegExp(r'version\s+([\d\.]+)').firstMatch(stdout);
      return match != null ? match.group(1) ?? '' : '';
    });
  }
}
