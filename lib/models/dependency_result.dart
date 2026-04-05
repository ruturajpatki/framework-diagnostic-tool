class DependencyResult {
  final String name;
  final bool isInstalled;
  final String version;
  final String rawOutput;
  final String? error;

  DependencyResult({
    required this.name,
    required this.isInstalled,
    required this.version,
    required this.rawOutput,
    this.error,
  });
}
