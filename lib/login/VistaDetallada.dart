import 'dart:async';
import 'dart:convert';
import 'package:conduent/login/VistaReporte.dart';
import 'package:conduent/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VistaDetallada extends StatefulWidget {
  final String idIncidencia;
  final String nombreUsuario;
  final UserData userData;

  const VistaDetallada({Key? key, required this.idIncidencia, required this.nombreUsuario, required this.userData}) : super(key: key);

  @override
  _VistaDetalladaState createState() => _VistaDetalladaState();
}

class _VistaDetalladaState extends State<VistaDetallada> with WidgetsBindingObserver {
  late Timer _sessionTimer;
  late Map<String, dynamic> incidenciaData;
  late String estado;
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Modificación: Se agrega el GlobalKey
  List<dynamic> historialAcciones = [];

  @override
  void initState() {
    super.initState();
    // Iniciar temporizador para actualizar sesión cada 2 minutos
    _sessionTimer = Timer.periodic(const Duration(minutes: 2), (_) => updateLogin());

    obtenerDetalleIncidencia();
    obtenerHistorialAcciones();
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    // Detener temporizador al cerrar el widget
    _sessionTimer.cancel();


    WidgetsBinding.instance.removeObserver(this);
    // Llamar a la función para registrar la salida de la sesión
    //enviarCerrarSeccion();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('State: $state');
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        // La aplicación está en un estado inactivo, como cuando se interrumpe una llamada telefónica.
        //enviarCerrarSeccion();
        //updateLogin();
        break;
      case AppLifecycleState.hidden:
        // La aplicación está pausada, generalmente ocurre cuando la aplicación se envía a segundo plano.
        // Puedes llamar a enviarCerrarSeccion() aquí si lo deseas.
        //updateLogin();
        //enviarCerrarSeccion();
        break;
      case AppLifecycleState.paused:
        // La aplicación está en primer plano y reanuda.
        updateLogin();
        break;
      case AppLifecycleState.resumed:
        // La aplicación está en primer plano y reanuda.
        updateLogin();
        break;


      // Si estoy en el estado detached, cerrar la sesión, si no, actualizar la sesión
      case AppLifecycleState.detached:
        // La aplicación está completamente cerrada.
        //enviarCerrarSeccion();
        break;
    }
  }
  // Funcion para update Login
  // Api07
  Future<void> updateLogin() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateLogin');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idusuario': widget.userData.idUsuario}),
      );


      print('Tiempo sesion: ${response.body}');


      var data = json.decode(response.body);
      var estado = data['estado'];
      var msj = data['msj'];
      var result = data['result'];


      print('Resultado Update Login: $result');


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

//Api para obtener datos de inciendia al iniciar
  Future<void> obtenerDetalleIncidencia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getIncidencia');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idincidencia': widget.idIncidencia,
        }),
      );


      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var result = data['result'][0];
        setState(() {
          incidenciaData = result;
          estado = result['ULT_EST'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load incidencia details');
      }
    } catch (error) {
      print('Error: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }
//api para obtener historial de acciones de la incidencia
  Future<void> obtenerHistorialAcciones() async {
    try {
      var url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getIncidenciaEstados');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idincidencia': widget.idIncidencia,
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          historialAcciones = data['result'];
        });
      } else {
        throw Exception('Failed to load historial acciones');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

void activarReporte() {
  if (estado == '18') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VistaReporte(
        nombreUsuario: widget.userData.nombreUsuario, 
        idUsuario: widget.userData.idUsuario,
        idIncidencia: widget.idIncidencia,
      )),
    ).then((value) {
      obtenerDetalleIncidencia();
      obtenerHistorialAcciones();
    });
  } else if (estado == '19') {
    Navigator.pop(context); // Cerrar la vista
  } else {
    _updateEstado(widget.idIncidencia);
  }
}



Future<void> _updateEstado(String idIncidencia) async {
  try {
    var url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateEstadoIncidencia');
    var response = await http.post(
      url,
    
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idusuario': widget.userData.idUsuario,
        'idincidencia': idIncidencia,
      }),
    );

    var data = json.decode(response.body);
    var estado = data['estado'];
    var msj = data['msj'];

    print('Estado de la actualización: $estado');
    print('Mensaje de la actualización: $msj');
  } catch (error) {
    print('Error al realizar algo especial: $error');
  }
    obtenerDetalleIncidencia();
    obtenerHistorialAcciones();
}

  Color getColorForStatus(String status) {
    switch (status) {
      case 'SIN RECEPCIONAR':
        return Colors.red;
      case 'RECEPCIONADO':
        return Colors.orange;
      case 'EN ATENCION':
        return Colors.blueGrey;
      case 'ATENDIDO':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario: ${widget.nombreUsuario}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Detalles de Incidencia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Cargando datos de incidencia',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario: ${widget.nombreUsuario}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Detalles de Incidencia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${incidenciaData['DESC_ESTADO']} desde el ${incidenciaData['FEC_ULT_EST']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getColorForStatus(incidenciaData['DESC_ESTADO']),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text(
                      'ID de Incidencia: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('${incidenciaData['ID_INCIDENCIA']}'),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Tipo de Equipo: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('${incidenciaData['NOM_TIPO_UBICACION']}'),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Tipo de Incidencia: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${incidenciaData['DESCRIPCION']}',
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Emplazamiento del equipo: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${incidenciaData['EMPLAZAMIENTO']}',
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Historial de acciones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historialAcciones.length,
                itemBuilder: (context, index) {
                  var accion = historialAcciones[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${accion['DESC_ESTADO']} por ${accion['NOMBRE_USU']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Fecha: ${accion['FEC_REGISTRO']}'),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: estado == '19' ? null : BottomAppBar(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
          ),
          onPressed: () => activarReporte(),
        child: Text(
         estado == '16'
            ? 'Iniciar atención'
             : estado == '17'
               ? 'Terminar atención'
                 : estado == '18'
                   ? 'Iniciar Reporte'
                     : estado == '19'
                      ? 'Finalizar Incidencia'
                       : 'Cargando',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ),
      ),
    );
  }



  // Funciones para mostrar diálogos
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
}
