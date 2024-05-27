import 'package:conduent/login/VistaLogin.dart';
import 'package:flutter/material.dart';

class TipoEquipo {
  final String nombre;
  final String id;
  TipoEquipo({required this.nombre, required this.id});
}

class RegistrarOrdenTrabajo extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final UserData userData;

  const RegistrarOrdenTrabajo({
    Key? key,
    required this.usuario,
    required this.contrasenia,
    required this.userData,
  }) : super(key: key);

  @override
  _RegistrarOrdenTrabajoState createState() => _RegistrarOrdenTrabajoState();
}

class _RegistrarOrdenTrabajoState extends State<RegistrarOrdenTrabajo> with WidgetsBindingObserver {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Orden de Trabajo'),
      ),
      body: Container(
        child: Column(
          children: [
            const SizedBox(height: 1),
            // Selecionar Tipo Incidencia
            const Text('Placa de Bus'),
            SizedBox(
              height: 60,
              width: double.infinity,
              child: Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Autocomplete<String>(
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete)
                  {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Digite aquí',
                        hintStyle: TextStyle(
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    );
                  }, optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return ['Placa 1', 'Placa 2', 'Placa 3', 'Placa 4', 'Placa 5', 'Placa 6', 'Placa 7', 'Placa 8', 'Placa 9', 'Placa 10'];
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}