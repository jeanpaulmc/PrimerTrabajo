import 'dart:async';
import 'dart:convert';
import 'package:conduent/login/serviceNotificacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'lista_view_mantenimiento.dart';
import 'login_view.dart';

class TipoTramo {
  final String nombre;
  final String id;

  TipoTramo({required this.nombre, required this.id});
}

class EnviarMantenimiento extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final UserData userData;

  const EnviarMantenimiento({
    Key? key,
    required this.usuario,
    required this.contrasenia,
    required this.userData,
  }) : super(key: key);

  @override
  _EnviarMantenimientoState createState() => _EnviarMantenimientoState();
}

class _EnviarMantenimientoState extends State<EnviarMantenimiento>
    with WidgetsBindingObserver {
  late Timer _sessionTimer;
  List<TipoTramo> tramoOptions = [];
  String? selectedTramoId;
  String? nombreTramo;
  bool isButtonEnabled = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _sessionTimer =
        Timer.periodic(const Duration(minutes: 2), (_) => updateLogin());
    verTramo();
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _sessionTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        updateLogin();
        break;
      case AppLifecycleState.resumed:
        updateLogin();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> updateLogin() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateLogin');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idusuario': widget.userData.idUsuario}),
      );

      var data = json.decode(response.body);
      var estado = data['estado'];
      var msj = data['msj'];

      switch (estado) {
        case 1:
          print('Sesión actualizada');
          break;
        case 0:
          mostrarError(msj);
          break;
        case -1:
          mostrarError(msj);
          break;
        case -2:
          mostrarError(msj);
          break;
        default:
          break;
      }
    } catch (error) {
      print('Error al cerrar sesión: $error');
    }
  }

  void verTramo() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getListaTramo');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'selected_value': selectedTramoId}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          tramoOptions = List<TipoTramo>.from(data['result'].map((item) =>
              TipoTramo(
                nombre: item['DESCRIPCION'].toString(),
                id: item['ID_TRAMO'].toString(),
              )));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load equipo options');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void onTramoSelected(String? newValue) {
    setState(() {
      selectedTramoId = newValue;
      nombreTramo = tramoOptions
          .firstWhere((element) => element.id == newValue, orElse: () => TipoTramo(nombre: "", id: ""))
          .nombre;
      isButtonEnabled = newValue != null;
    });
  }

  void consultarAPI() async {
    var url = Uri.parse(
        'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateTramoLogin');

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idsession': widget.userData.idSeccion,
          'idtramo': selectedTramoId,
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String estado = data['estado'];

        if (estado == '1') {
          ingresarLista();
        } else if (estado == '-2') {
          mostrarError('Sección errónea');
        } else {
          mostrarError('Error al consultar');
        }
      } else {
        mostrarError('Error en la solicitud: ${response.statusCode}');
      }
    } catch (error) {
      mostrarError('Error: $error');
    }
  }


  // Función para cerrar la sesión
  Future<void> enviarCerrarSeccion() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/cerrarLogin');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idsession': widget.userData.idSeccion,
        }),
      );


      print('Response Cerrar Seccion Login: ${response.body}');


      var data = json.decode(response.body);
      var estado = data['estado'];
      var msj = data['msj'];
      var result = data['result'];


      print('Resultado 2: $result');


      switch (estado) {
        case 1:
          print('Sesión cerrada');
          break;
        case 0:
          mostrarError(msj);
          break;
        case -1:
          mostrarError('La sesión no existe');
          break;
        case -2:
          mostrarError('Campo faltante');
          break;
        case -3:
          mostrarError('La sesión fue cerrada anteriormente');
          break;
        default:
          break;
      }
    } catch (error) {
      print('Error al cerrar sesión: $error');
      mostrarError('Error al cerrar sesión: $error');
    }
  }


  void ingresarLista() {
    var idUsuario = widget.userData.idUsuario;
    var nombreUsuario = widget.userData.nombreUsuario;

    UserData userData = UserData(
      idUsuario: idUsuario,
      nombreUsuario: nombreUsuario,
      idSeccion: widget.userData.idSeccion,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaViewMantenimiento(
          usuario: widget.usuario,
          contrasenia: widget.contrasenia,
          selectedTramoId: selectedTramoId,
          nombreTramo: nombreTramo,
          userData: userData,
        ),
      ),
    );
  }

  void mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Salir de la aplicación'),
            content: Text('¿Quieres salir de la aplicación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: (){
                  SystemNavigator.pop();
                  enviarCerrarSeccion();
                },
                child: Text('Sí'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
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
                    'Seccion de Mantenimiento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ) 
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Seleccionar Tramo'),
                    SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          value: selectedTramoId,
                          icon: const Icon(Icons.arrow_drop_down),
                          style: const TextStyle(color: Colors.black, fontSize: 13),
                          underline: Container(
                            height: 0,
                            color: Colors.transparent,
                          ),
                          onChanged: onTramoSelected,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Center(child: Text('Seleccionar')),
                            ),
                            ...tramoOptions.map((TipoTramo tipoTramo) {
                              return DropdownMenuItem<String>(
                                value: tipoTramo.id,
                                child: Center(child: Text(tipoTramo.nombre)),
                              );
                            }),
                          ],
                          dropdownColor: Colors.grey[200],
                          elevation: 0,
                          isExpanded: true,
                          onTap: () {},
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: ElevatedButton(
                        onPressed: isButtonEnabled ? consultarAPI : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text(
                          'Ingresar Tramo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),


                     ElevatedButton(
          onPressed: () {
            // Aquí debemos mostrar la notificación
            showNotificacion1();
          },
          child: const Text('Mostrar la notificación')),

                  ],
                ),
        ),
      ),
    );
  }
}
