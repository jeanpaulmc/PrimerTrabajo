import 'dart:async';
import 'dart:convert';
import 'package:conduent/login/VistaDetallada.dart';
import 'package:conduent/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VistaFinalizados extends StatefulWidget {
  final String nombreUsuario;
  final String userID;
  final UserData userData;

  const VistaFinalizados({Key? key, 
  required this.nombreUsuario, 
  required this.userID, 
  required this.userData,
  }) : super(key: key);

  @override
  _VistaFinalizadosState createState() => _VistaFinalizadosState();
}

class _VistaFinalizadosState extends State<VistaFinalizados> {
  late DateTime fechaInicio = DateTime.now();
  late DateTime fechaTerminado = DateTime.now();
  bool _isLoading = false;
  bool _fechasSeleccionadas = false;
  List<Map<String, dynamic>> _incidencias = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> verIncidenciafinalizada() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var idUsuario = widget.userID;
      var inicio = fechaInicio;
      var fin = fechaTerminado;
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getListaIncidenciasFin');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idusuario': idUsuario,
          'fechaini': inicio.toString(),
          'fechafin': fin.toString(),
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var result = data['result'];
        var estado = data['estado'];
        print('Estado: $estado');
        print('Result: $result');

        setState(() {
          _isLoading = false;
          _incidencias = List<Map<String, dynamic>>.from(result);
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

  Future<void> seleccionarFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        fechaInicio = picked;
      });
    }
  }

  Future<void> seleccionarFechaTerminado(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        fechaTerminado = picked;
        _fechasSeleccionadas = true;
      });
    }
  }

  void _detalladaFinal(String idIncidencia) async {
    // Navegar a VistaDetallada
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VistaDetallada(
            idIncidencia: idIncidencia,
            nombreUsuario: widget.nombreUsuario,
            userData: widget.userData, 
        ),
      ),
    );
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
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Usuario: ${widget.nombreUsuario}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
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
      body: Align(
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
  margin: EdgeInsets.symmetric(horizontal: 20), 

  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: () => seleccionarFechaInicio(context),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.orange,
          ),
          child: Column(
            children: [
              const Text(
                'Desde',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              Text(
                fechaInicio.toString().substring(0, 10),
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton(
          onPressed: () => seleccionarFechaTerminado(context),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.orange,
          ),
          child: Column(
            children: [
              const Text(
                'Hasta',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              Text(
                fechaTerminado.toString().substring(0, 10),
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),

            SizedBox(height: 20),
            if (_fechasSeleccionadas)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _incidencias.map((incidencia) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () => _detalladaFinal(incidencia['ID_INCIDENCIA']),
                          child: Card(
                            elevation: 5,
                            child: ListTile(
                              subtitle: Column(
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
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
          ),
          onPressed: _fechasSeleccionadas ? verIncidenciafinalizada : null,
          child: const Text(
            'Buscar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
