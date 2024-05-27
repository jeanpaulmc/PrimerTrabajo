import 'dart:io';
import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';

import 'listaOrdenTrabajo.dart';
import 'package:conduent/login/VistaLogin.dart';

class TipoEquipo {
  final String nombre;
  final String id;
  TipoEquipo({required this.nombre, required this.id});
}

class EnviarTecnico extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final UserData userData;

  const EnviarTecnico({
    Key? key,
    required this.usuario,
    required this.contrasenia,
    required this.userData,
  }) : super(key: key);

  @override
  _EnviarTecnicoState createState() => _EnviarTecnicoState();
}

class _EnviarTecnicoState extends State<EnviarTecnico> with WidgetsBindingObserver {
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificarCara(); // Llama al método para abrir la cámara automáticamente
  }

  Future<void> _verificarCara() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Autorización Face'),
          ),
          body: _buildCameraBody(),
        ),
      ),
    );
  }

  Widget _buildCameraBody() {
    return Builder(
      builder: (context) {
        return SmartFaceCamera(
          autoCapture: true,
          defaultCameraLens: CameraLens.front,
          onCapture: (File? image) {
            if (image != null) {
              setState(() {
                _capturedImage = image;
              });
              Navigator.pop(context); // Vuelve a la pantalla anterior una vez capturada la imagen
            }
          },
          onFaceDetected: (Face? face) {
            // Puede usarse para mostrar mensajes si la cara está detectada o no
          },
          messageBuilder: (context, face) {
            if (face == null) {
              return _buildMessage('Cara no detectada');
            }
            if (!face.wellPositioned) {
              return _buildMessage('Cara no está bien posicionada');
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildMessage(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar técnico'),
      ),
      body: Center(
        child: _capturedImage == null
            ? const CircularProgressIndicator() // Muestra un indicador mientras se espera la captura de imagen
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(
                    _capturedImage!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrdePT(
                            userData: widget.userData,
                            usuario: widget.usuario,
                            contrasenia: widget.contrasenia,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Iniciar Sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
