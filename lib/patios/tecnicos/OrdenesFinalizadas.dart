import 'package:conduent/login/VistaLogin.dart';
import 'package:flutter/material.dart';

class TipoEquipo {
  final String nombre;
  final String id;
  TipoEquipo({required this.nombre, required this.id});
}

class OrdenesFinalizadas extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final UserData userData;

  const OrdenesFinalizadas({
    Key? key,
    required this.usuario,
    required this.contrasenia,
    required this.userData,
  }) : super(key: key);

  @override
  _OrdenesFinalizadasState createState() => _OrdenesFinalizadasState();
}

class _OrdenesFinalizadasState extends State<OrdenesFinalizadas> with WidgetsBindingObserver {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ordenes Finalizadas'),
      ),
      body: Container(
        child: Column(
          children: [
            Text('Ordenes Finalizadas'),
          ],
        ),
      ),
    );
  }
}