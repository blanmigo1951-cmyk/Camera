import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiCamaraEstudioApp());
}

class MiCamaraEstudioApp extends StatelessWidget {
  const MiCamaraEstudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cámara Estudio Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.amber,
      ),
      home: const PantallaCamaraEstudio(),
    );
  }
}

class PantallaCamaraEstudio extends StatefulWidget {
  const PantallaCamaraEstudio({super.key});

  @override
  State<PantallaCamaraEstudio> createState() => _PantallaCamaraEstudioState();
}

class _PantallaCamaraEstudioState extends State<PantallaCamaraEstudio> {
  static const platform = MethodChannel('com.estudiopro/camara');
  
  bool _permisoConcedido = false;
  bool _procesandoFoto = false;
  String _estadoMensaje = "Inicializando optimizadores...";

  @override
  void initState() {
    super.initState();
    _verificarYPedirPermisos();
  }

  Future<void> _verificarYPedirPermisos() async {
    final estadoCamara = await Permission.camera.request();
    
    if (estadoCamara.isGranted) {
      setState(() {
        _permisoConcedido = true;
      });
      _iniciarMotorPotenciado();
    } else {
      setState(() {
        _estadoMensaje = "Se requiere permiso de cámara para continuar.";
      });
    }
  }

  Future<void> _iniciarMotorPotenciado() async {
    try {
      await platform.invokeMethod('iniciarCamaraPotenciada');
      setState(() {
        _estadoMensaje = "Modo Estudio Activo: HDR + Reducción de Ruido";
      });
    } on PlatformException catch (e) {
      setState(() {
        _estadoMensaje = "Error al activar motor: ${e.message}";
      });
    }
  }

  Future<void> _capturarFotoEstudio() async {
    if (_procesandoFoto) return;

    setState(() {
      _procesandoFoto = true;
      _estadoMensaje = "Procesando nitidez e iluminación de estudio...";
    });

    try {
      final String respuesta = await platform.invokeMethod('capturarFotoEstudio');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al procesar foto: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesandoFoto = false;
          _estadoMensaje = "Modo Estudio Activo: Listo para la siguiente toma";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permisoConcedido) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_enhance, size: 80, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  _estadoMensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: _verificarYPedirPermisos,
                  child: const Text('Conceder Permisos', style: TextStyle(color: Colors.black)),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const Center(
            child: Text(
              "Visor Potenciado en Tiempo Real\n(Ajuste automático de color, nitidez y fondo)",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _estadoMensaje,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _capturarFotoEstudio,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 4),
                    color: _procesandoFoto ? Colors.grey : Colors.white,
                  ),
                  child: _procesandoFoto
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: Colors.amber),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.black, size: 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
