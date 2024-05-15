import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Versao extends StatefulWidget {
  const Versao({super.key});

  @override
  State<Versao> createState() => _VersaoState();
}

class _VersaoState extends State<Versao> {
  String _appVersion = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Versão'),
      ),
      body: Center(
        child: Text('Versão $_appVersion'),
      ),
    );
  }
}
