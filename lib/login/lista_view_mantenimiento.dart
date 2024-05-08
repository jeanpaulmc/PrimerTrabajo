import 'dart:async';
import 'dart:convert';
import 'package:conduent/login/VistaDetallada.dart';
import 'package:conduent/login/VistaFinalizados.dart';
import 'package:conduent/login/enviar_view_personal.dart';
import 'package:conduent/login/login_view.dart';
import 'package:conduent/login/serviceNotificacion.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


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
  late Timer _sessionTimer;
  bool _screenIsOn = true;
  late String lastDate;
   final Map<String, bool> _expansionPanelState = {
  'Incidencias sin recepcionar': false,
  'Incidencias recepcionadas': false,
  'Incidencias en atencion': false,
  'Incidencias atendidas': false,
};
  List<Map<String, dynamic>> _lista1 = [];
  List<Map<String, dynamic>> _lista2 = [];
  List<Map<String, dynamic>> _lista3 = [];
  List<Map<String, dynamic>> _lista4 = [];
  int pendientesSinAtender = 0;
  int pendientesEnAtencion = 0;
  int incidenciaLista1 = 0;
  int incidenciaLista2 = 0;
  int incidenciaLista3 = 0;
  int incidenciaLista4 = 0;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    WidgetsBinding.instance.addObserver(this);
    verIncidencia();
  }


  @override
  void dispose() {
    _sessionTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateLoginIfNeeded();
    });
  }


  void _updateLoginIfNeeded() {
    if (_screenIsOn) {
      updateLogin();
      consultarIncidenciaNueva();
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _screenIsOn = true;
        _updateLoginIfNeeded();
        _startSessionTimer();
        break;
      case AppLifecycleState.resumed:
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
            setState(() {
              lastDate = lastFec;
            });
          }
          showNotificacion1();
          verIncidencia();
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
      var url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateLogin');
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
      var url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getListaIncidenciasPen');
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
        incidenciaLista1 = 0;
        incidenciaLista2 = 0;
        incidenciaLista3 = 0;
        incidenciaLista4 = 0;
       
        _lista1.clear();
        _lista2.clear();
        _lista3.clear();
        _lista4.clear();


        for (var incidencia in result) {
          var descEstado = incidencia['ULT_EST'];
          switch (descEstado) {
            case '15':
              _lista1.add(incidencia);
              pendientesSinAtender++;
              incidenciaLista1++;
              break;
            case '16':
              _lista2.add(incidencia);
              pendientesSinAtender++;
              incidenciaLista2++;
              break;
            case '17':
              _lista3.add(incidencia);
              pendientesEnAtencion++;
              incidenciaLista3++;
              break;
            case '18':
              _lista4.add(incidencia);
              pendientesEnAtencion++;
              incidenciaLista4++;
              break;
            default:
              break;
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
    if (_lista1.isEmpty) {
      var now = DateTime.now();
      var formatter = DateFormat('dd/MM/yyyy 00:00:00');
      lastDate = formatter.format(now);
      print('fecha vacia $lastDate');
    } else {
      var incidenciasEstado15 =
          _lista1.where((incidencia) => incidencia['descEstado'] == '15').toList();


      if (incidenciasEstado15.isNotEmpty) {
        var ultimaIncidenciaEstado15 = incidenciasEstado15.reduce((a, b) =>
            a['FEC_ULT_EST_COMPLETO'].compareTo(b['FEC_ULT_EST_COMPLETO']) > 0 ? a : b);
        lastDate = ultimaIncidenciaEstado15['FEC_ULT_EST_COMPLETO'];
        print('fecha ultima con estado 15: $lastDate');
      } else {
        var ultimaIncidencia =
            _lista1.reduce((a, b) => a['FEC_ULT_EST_COMPLETO'].compareTo(b['FEC_ULT_EST_COMPLETO']) > 0 ? a : b);
        lastDate = ultimaIncidencia['FEC_ULT_EST_COMPLETO'];
        print('fecha ultima sin estado 15: $lastDate');
      }
    }
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


  Color getColorAlerts(String tiempo) {
    switch (tiempo) {
      case '30':
        return Colors.orange;
      case '60':
        return Colors.red;
      case '120':
        return Colors.purple;
      case '0':
        return Colors.green;
      default:
        return Colors.black;
    }
  }


  void _finalizar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VistaFinalizados(
          nombreUsuario: widget.userData.nombreUsuario,
          userID: widget.userData.idUsuario,
          userData: widget.userData,
        ),
      ),
    ).then((value) {
      verIncidencia();
    });
  }

    void _RegistroIncidendia() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnviarPersonal(
          usuario: widget.usuario,
          contrasenia: widget.contrasenia,
          userData: widget.userData,
        ),
      ),
    ).then((value) {
      verIncidencia();
    });
  }



  void _detallada(String idIncidencia) async {
    var incidencia = _lista1.firstWhere((element) => element['ID_INCIDENCIA'] == idIncidencia, orElse: () => {});
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


  void _toggleExpansionPanelState(int index) {
  switch (index) {
    case 0:
      _expansionPanelState['Incidencias sin recepcionar'] = !_expansionPanelState['Incidencias sin recepcionar']!;
      break;
    case 1:
      _expansionPanelState['Incidencias recepcionadas'] = !_expansionPanelState['Incidencias recepcionadas']!;
      break;
    case 2:
      _expansionPanelState['Incidencias en atencion'] = !_expansionPanelState['Incidencias en atencion']!;
      break;
    case 3:
      _expansionPanelState['Incidencias atendidas'] = !_expansionPanelState['Incidencias atendidas']!;
      break;
    default:
      break;
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
                                onTap: verIncidencia,
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
                            _buildExpansionPanelList(),
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


          Positioned(
            left: 16.0,
            bottom: 16.0,
            child: GestureDetector(
              onTap: _RegistroIncidendia,
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
          ),
        ],
      ),
    );
  }


Widget _buildExpansionPanelList() {
  return ExpansionPanelList(
    expansionCallback: (int index, bool isExpanded) {
      setState(() {
        _toggleExpansionPanelState(index);
      });
    },
    children: [
      _buildExpansionPanel(
        title: 'Incidencias sin recepcionar',
        incidencias: _lista1,
        color: Colors.red,
        isExpanded: false,
        itemCount: incidenciaLista1,
      ),
      _buildExpansionPanel(
        title: 'Incidencias recepcionadas',
        incidencias: _lista2,
        color: Colors.orange,
        isExpanded: false,
        itemCount: incidenciaLista2,
      ),
      _buildExpansionPanel(
        title: 'Incidencias en atencion',
        incidencias: _lista3,
        color: Colors.blueGrey,
        isExpanded: false,
        itemCount: incidenciaLista3,
      ),
      _buildExpansionPanel(
        title: 'Incidencias atendidas',
        incidencias: _lista4,
        color: Colors.green,
        isExpanded: false,
        itemCount: incidenciaLista4,
      ),
    ],
  );
}


ExpansionPanel _buildExpansionPanel({
  required String title,
  required int itemCount,
  required List<Map<String, dynamic>> incidencias,
  required Color color,
  required bool isExpanded,
}) {
  return ExpansionPanel(
    canTapOnHeader: true,
    headerBuilder: (BuildContext context, bool isExpanded) {
      return ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _expansionPanelState[title] = !_expansionPanelState[title]!;
                });
              },
             
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _expansionPanelState[title] = !_expansionPanelState[title]!;
          });
        },
      );
    },
    body: Column(
      children: incidencias.map((incidencia) {
        var status = incidencia['DESC_ESTADO'];
        var textColor = getColorForStatus(status);
        var tiempo = incidencia['TIEMPO_SIN_ATENDER'];
        var alerColor = getColorAlerts(tiempo);
        return GestureDetector(
          onTap: () => _detallada(incidencia['ID_INCIDENCIA']),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
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
                          'Equipo: ${incidencia['NOM_TIPO_UBICACION']}',
                        ),
                        Text(
                          'Emp. ${incidencia['EMPLAZAMIENTO']}',
                        ),
                      ],
                    ),
                    Text('Incidencia: ${incidencia['DESCRIPCION']}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${incidencia['DESC_ESTADO']} desde el ${incidencia['FEC_ULT_EST']}',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
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
    isExpanded: _expansionPanelState[title]!,
  );
}
}