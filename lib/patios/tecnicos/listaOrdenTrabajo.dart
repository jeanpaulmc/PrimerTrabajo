import 'package:conduent/login/VistaLogin.dart';
import 'package:flutter/material.dart';
//import 'OrdenesFinalizadas.dart';
import 'RegistrarOrdenTrabajo.dart';


class TipoEquipo {
  final String nombre;
  final String id;
  TipoEquipo({required this.nombre, required this.id});
}

class OrdePT extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final UserData userData;

  const OrdePT({
    Key? key,
    required this.usuario,
    required this.contrasenia,
    required this.userData,
  }) : super(key: key);

  @override
  _OrdePTState createState() => _OrdePTState();
}

class _OrdePTState extends State<OrdePT> with WidgetsBindingObserver {

  void registrasOPT() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrarOrdenTrabajo(
          usuario: widget.usuario,
          contrasenia: widget.contrasenia,
          userData: widget.userData,
        ),
      ),
    );
  }

/*
  void finalizados() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdenesFinalizadas(
          usuario: widget.usuario,
          contrasenia: widget.contrasenia,
          userData: widget.userData,
        ),
      ),
    );
  }
*/


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario: ${widget.userData.nombreUsuario}',
                  style: const TextStyle(
                    fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Lista de ordenes de trabajo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        
        children: [
        /*
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: GestureDetector(
              onTap: finalizados,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'Finalizados',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        */
          Positioned(
            left: 16.0,
            bottom: 16.0,
            child: GestureDetector(
              onTap: registrasOPT,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'Registrar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )


        ],
      ),
    );
  }

}