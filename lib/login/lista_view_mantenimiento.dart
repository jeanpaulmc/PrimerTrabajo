import 'dart:async';
import 'dart:convert';
import 'package:conduent/login/serviceNotificacion.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:conduent/login/login_view.dart';
import 'package:conduent/login/VistaDetallada.dart';
import 'package:conduent/login/VistaFinalizados.dart';
import 'package:intl/intl.dart';
import 'package:wakelock/wakelock.dart';

class ListaViewMantenimiento extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final String? selectedTramoId;
  final String? nombreTramo;
  final UserData userData;

  const ListaViewMantenimiento({
    Key? key,
    required this.usuario,
    required this.contrasenia,
    this.selectedTramoId,
    this.nombreTramo,
    required this.userData,
  }) : super(key: key);

  @override
  _ListaViewMantenimientoState createState() => _ListaViewMantenimientoState();
}

class _ListaViewMantenimientoState extends State<ListaViewMantenimiento> with WidgetsBindingObserver {
  // Crear un controlador para el campo de texto del emplazamiento
  late Timer _sessionTimer;
  
  // Inicialmente asumimos que la pantalla está encendida
  bool _screenIsOn = true;


  List<Map<String, dynamic>> _listaSinAtender = [];
  List<Map<String, dynamic>> _listaEnAtencion = [];
  int pendientesSinAtender = 0;
  int pendientesEnAtencion = 0;
  bool comando = false;
  bool _isLoading = false;
  late String lastDate;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    Wakelock.enable();

    verIncidencia();
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _sessionTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateLoginIfNeeded();
    });
  }

  void _updateLoginIfNeeded() {
    if (_screenIsOn) {
      // La pantalla está encendida, realiza las acciones necesarias
      updateLogin();
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        _screenIsOn = true;
        _updateLoginIfNeeded();
        _startSessionTimer();
        break;
      case AppLifecycleState.hidden:
        _screenIsOn = true;
        _updateLoginIfNeeded();
        _startSessionTimer();
        break;
      case AppLifecycleState.paused:
        // La aplicación está en segundo plano o en estado de pausa, continúa actualizando el inicio de sesión cada 2 minutos
        _screenIsOn = true;
        _updateLoginIfNeeded();
        _startSessionTimer(); // Aquí se vuelve a iniciar el temporizador
        break;
      case AppLifecycleState.resumed:
        // Se reanuda la aplicación, comienza a actualizar el inicio de sesión cada 2 minutos hasta que cambie de estado nuevamente
        _screenIsOn = true;
        _updateLoginIfNeeded();
        _startSessionTimer();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }


  Future<void> consultarIncidenciaNueva() async {
  try {
    var url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getIncidenciaNueva');
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idusuario': widget.userData.idUsuario,
        'lastdate': lastDate,
      }),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      var cant = data['result'][0]['CANT'] as String;
      var lastFec = data['result'][0]['LAST_FEC'] as String?;
      if (cant == '0') {
        print('El valor de "CANT" es 0');
        print('La fecha es $lastFec');
      } else {
        print('El valor de "CANT" $cant');
        print('La fecha nueva $lastFec');
        if (lastFec != null) {
          // Actualizar el valor de lastDate
          setState(() {
          });
        }
        showNotificacion1();
        verIncidencia();
        lastDate = lastFec!;
      }
    } else {
      print('Error al consultar la incidencia nueva: ${response.statusCode}');
    }
  } catch (error) {
    print('Error al consultar: $error');
  }
}

  Future<void> updateLogin() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateLogin');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idsession': widget.userData.idSeccion}),
      );

      print('Tiempo sesion: ${response.body}');

      var data = json.decode(response.body);
      var estado = data['estado'];
      var msj = data['msj'];
      var result = data['result'];
      var idsession = data['idsession'];

      print('Aca idsession: ${idsession}');
      
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

  void mostrarError(String msj) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(msj),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }


  void verIncidencia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var idUsuario = widget.userData.idUsuario;
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getListaIncidenciasPen');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idusuario': idUsuario,
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var result = data['result'];

        pendientesSinAtender = 0;
        pendientesEnAtencion = 0;
        _listaSinAtender.clear();
        _listaEnAtencion.clear();

        for (var incidencia in result) {
          var descEstado = incidencia['ULT_EST'];
          if (descEstado == '15' || descEstado == '16') {
            _listaSinAtender.add(incidencia);
            pendientesSinAtender++;
          } else if (descEstado == '17' || descEstado == '18') {
            _listaEnAtencion.add(incidencia);
            pendientesEnAtencion++;
          }
        }
        setState(() {
          _isLoading = false;
          fechaParaApi();
        });
      } else {
        throw Exception('Failed to load incidencia options');
      }
    } catch (error) {
      print('Error: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

void fechaParaApi() async {
  if (_listaSinAtender.isEmpty) {
    // Obtener la fecha actual y formatearla como se requiere
    var now = DateTime.now();
    var formatter = DateFormat('dd/MM/yyyy 00:00:00');
    lastDate = formatter.format(now);
    print('fecha vacia $lastDate');
  } else {
    var incidenciasEstado15 =
        _listaSinAtender.where((incidencia) => incidencia['descEstado'] == '15').toList();

    if (incidenciasEstado15.isNotEmpty) {
      // Si hay incidencias con descEstado igual a '15', obtén la fecha de la última incidencia con ese estado
      var ultimaIncidenciaEstado15 = incidenciasEstado15.reduce((a, b) =>
          a['FEC_ULT_EST_COMPLETO'].compareTo(b['FEC_ULT_EST_COMPLETO']) > 0 ? a : b);
      lastDate = ultimaIncidenciaEstado15['FEC_ULT_EST_COMPLETO'];
      print('fecha ultima con estado 15: $lastDate');
    } else {
      // Si no hay incidencias con descEstado igual a '15', obtén la fecha de la última incidencia sin importar el estado
      var ultimaIncidencia =
          _listaSinAtender.reduce((a, b) => a['FEC_ULT_EST_COMPLETO'].compareTo(b['FEC_ULT_EST_COMPLETO']) > 0 ? a : b);
      lastDate = ultimaIncidencia['FEC_ULT_EST_COMPLETO'];
      print('fecha ultima sin estado 15: $lastDate');
    }
  }
}

  //actualizar pagina
  void _actualizar() {
    verIncidencia();
  }
  // Color de titulos
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

    // Color de alertas
  Color getColorAlerts(String tiempo) {
    switch (tiempo) {
      case '30':
        return Colors.orange;
      case '60':
        return Colors.red;
      case '120':
        return Colors.purple;
      case '0':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  void _finalizar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VistaFinalizados(
        nombreUsuario: widget.userData.nombreUsuario,
        userID: widget.userData.idUsuario,
        userData: widget.userData,
        )
      ),
    ).then((value) {
      verIncidencia();
    });
  }

void _detallada(String idIncidencia) async {
  var incidencia = _listaSinAtender.firstWhere((element) => element['ID_INCIDENCIA'] == idIncidencia, orElse: () => {});
  if (incidencia['ULT_EST'] == '15') {
    await _updateEstado(incidencia['ID_INCIDENCIA']); 
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VistaDetallada(
        idIncidencia: idIncidencia,
        nombreUsuario: widget.userData.nombreUsuario,
        userData: widget.userData,
      ),
    ),
  ).then((value) {
    verIncidencia();
  });
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
  }

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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Sección de Mantenimiento',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Text(
                                  'Pendientes: $pendientesSinAtender',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Realizadas: $pendientesEnAtencion',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            GestureDetector(
                              onTap: _actualizar,
                              child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Icon(
                              Icons.autorenew, 
                              color: Colors.white,
                              size: 24, 
                               ),
                              ),
                             ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Tramo: ${widget.nombreTramo}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_listaSinAtender.isNotEmpty)
                              _buildIncidenciasGroup(
                                title: 'Incidencias Pendientes',
                                incidencias: _listaSinAtender,
                                color: Colors.red,
                              ),
                            if (_listaEnAtencion.isNotEmpty)
                              _buildIncidenciasGroup(
                                title: 'Incidencias Realizadas',
                                incidencias: _listaEnAtencion,
                                color: Colors.blueGrey,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: GestureDetector(
              onTap: _finalizar,

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
        ],
      ),
    );
  }

  Widget _buildIncidenciasGroup({
    required String title,
    required List<Map<String, dynamic>> incidencias,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        Column(
          children: incidencias.map((incidencia) {
            var status = incidencia['DESC_ESTADO'];
            var textColor = getColorForStatus(status);
            var tiempo = incidencia['TIEMPO_SIN_ATENDER'];
            var alerColor = getColorAlerts(tiempo);
            return GestureDetector(
              onTap: () => _detallada(incidencia['ID_INCIDENCIA']),

              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tipo de Equipo: ${incidencia['NOM_TIPO_UBICACION']}',
                            ),
                            Text(
                              'Emplazamiento: ${incidencia['EMPLAZAMIENTO']}',
                            ),
                          ],
                        ),
                        Text(
                          'Incidencia: ${incidencia['DESCRIPCION']}'
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${incidencia['DESC_ESTADO']} desde el ${incidencia['FEC_ULT_EST']}',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),

                        //Alerta de tiempo
                      if (status == 'SIN RECEPCIONAR' && incidencia['TIEMPO_SIN_ATENDER'] != '0')
                        Container(
                      
                          width: double.infinity, 
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                decoration: BoxDecoration(
                                  color: alerColor,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  '> ${incidencia['TIEMPO_SIN_ATENDER']} minutos',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
