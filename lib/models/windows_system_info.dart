class WindowsSystemInfo {
  final String osName;
  final String osVersion;
  final String buildNumber;
  final String cpuModel;
  final int totalRamGB;
  final int numberOfCores;
  final bool is64Bit;
  final String computerName;

  WindowsSystemInfo({
    required this.osName,
    required this.osVersion,
    required this.buildNumber,
    required this.cpuModel,
    required this.totalRamGB,
    required this.numberOfCores,
    required this.is64Bit,
    required this.computerName,
  });
}
