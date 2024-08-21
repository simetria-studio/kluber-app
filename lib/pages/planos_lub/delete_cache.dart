import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeleteCache extends StatefulWidget {
  const DeleteCache({super.key});

  @override
  State<DeleteCache> createState() => _DeleteCacheState();
}

class _DeleteCacheState extends State<DeleteCache> {
  Future<void> _deleteCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Remover o cache específico para materiais e componentes
    await prefs.remove('materiais_cache');
    await prefs.remove('componentes_cache');

    // Exibir um alerta confirmando que o cache foi deletado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Cache de materiais e componentes deletado com sucesso.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deletar Cache'),
        backgroundColor: ColorConfig.amarelo,
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.delete_forever,
                color: Colors.redAccent,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Deseja deletar o cache dos materiais e componentes?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _deleteCache,
                icon: const Icon(Icons.delete),
                label: const Text(
                  'Deletar Cache',
                  style: TextStyle(fontSize: 18, color: ColorConfig.preto),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: ColorConfig.amarelo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
