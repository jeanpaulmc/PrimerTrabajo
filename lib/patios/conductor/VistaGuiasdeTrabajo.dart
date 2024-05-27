import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:conduent/login/VistaLogin.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class EnviarConductor extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final String? selectedTramoId;
  final String? nombreTramo;
  final UserData userData;


  const EnviarConductor({
    Key? key,
    required this.usuario,
    required this.contrasenia,
    this.selectedTramoId,
    this.nombreTramo,
    required this.userData,
  }) : super(key: key);


  @override
  _EnviarConductorState createState() => _EnviarConductorState();
}


class _EnviarConductorState extends State<EnviarConductor>
    with WidgetsBindingObserver {
  late Timer _sessionTimer;


  List<Map<String, dynamic>> _listaSinAtender = [];
  int pendientesSinAtender = 0;
  bool _isLoading = false;
  late String lastDate;


  @override
  void initState() {
    super.initState();
    verGuiasdeTrabajo();
    WidgetsBinding.instance.addObserver(this);
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }


  void verGuiasdeTrabajo() async {
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
        _listaSinAtender.clear();


        for (var incidencia in result) {
          _listaSinAtender.add(incidencia);
        }
        setState(() {
          _isLoading = false;
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


/*
  void _finalizar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VistaFinalizados(
        nombreUsuario: widget.userData.nombreUsuario,
        userID: widget.userData.idUsuario,
        userData: widget.userData,
        lastDate: lastDate,
        )
      ),
    ).then((value) {
      verGuiasdeTrabajo();
    });
  }
*/


/*
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
        lastDate: lastDate,
      ),
    ),
  ).then((value) {
    verIncidencia();
  });
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Listado de Guias de trabajo',
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
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Realizadas: $pendientesSinAtender',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              GestureDetector(
                                //onTap: _actualizar,
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
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIncidenciasGroup(
                              title: 'Lista de Guias de trabajo',
                              incidencias: _listaSinAtender,
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
              //onTap: (),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Column(
          children: incidencias.map((incidencia) {
            return GestureDetector(
              //onTap: () => _detallada(incidencia['ID_INCIDENCIA']),


              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                            const Text(
                              'Recojo de Equipos',
                            ),
                            Text(
                              'Emplazamiento: ${incidencia['EMPLAZAMIENTO']}',
                            ),
                          ],
                        ),
                        Text(
                          'Incidencia: ${incidencia['DESCRIPCION']}',
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${incidencia['DESC_ESTADO']} desde el ${incidencia['FEC_ULT_EST']}',
                            ),
                          ],
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
