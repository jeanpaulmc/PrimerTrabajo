import 'dart:async';
import 'dart:convert';
import 'package:conduent/login/enviar_view_matenimiento.dart';
import 'package:conduent/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;


import 'login_view.dart';




import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock/wakelock.dart';




class TipoEquipo {
  final String nombre;
  final String id;




  TipoEquipo({required this.nombre, required this.id});
}




class EnviarPersonal extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final UserData userData;








  const EnviarPersonal(
      {Key? key,
      required this.usuario,
      required this.contrasenia,
      required this.userData})
      : super(key: key);
















  @override
  _EnviarPersonalState createState() => _EnviarPersonalState();
}








class _EnviarPersonalState extends State<EnviarPersonal> with WidgetsBindingObserver {
 
  // Crear un controlador para el campo de texto del emplazamiento
  late Timer _sessionTimer;
 
  // Inicialmente asumimos que la pantalla está encendida
  bool _screenIsOn = true;






  List<TipoEquipo> equipoOptions = [];
  List<TipoEquipo> nombreIncidencia = [];




  String? selectedEquipoId;
  TextEditingController emplazamientoController = TextEditingController();
  String? selectedIncidenciaId;
  bool seccionHabilitada = false;
  List<TipoEquipo> incidenciaOptions = [];










  String? IdEmplazamiento;
  String? estadoEmplazamiento;
















  @override
  void initState() {
    super.initState();




    _startSessionTimer();
   


    Wakelock.enable(); // Mantener la pantalla encendida
    // Llamar a la función para ver el tipo de equipo
    verEquipo();
    emplazamientoController.addListener(_verificarCondiciones);
    WidgetsBinding.instance.addObserver(this);
  }




  void dispose() {
    // Detener temporizador al cerrar el widget
    _sessionTimer.cancel();
   
    WidgetsBinding.instance.removeObserver(this);
    emplazamientoController.dispose();
    // Llamar a la función para registrar la salida de la sesión
    //enviarCerrarSeccion();
    super.dispose();
  }








  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateLoginIfNeeded();
    });
  }




  void _updateLoginIfNeeded() {


    if(widget.userData.idTipoUsuario == '5' ||
      widget.userData.idTipoUsuario == '6' ||
      widget.userData.idTipoUsuario == '7'){
        if (_screenIsOn) {
          // La pantalla está encendida, realiza las acciones necesarias
          updateLogin();
        }
    }
  }








  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('State: $state');
   
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








  /*
  @override
  void initState() {
    super.initState();
    verEquipo();
    emplazamientoController.addListener(_verificarCondiciones);
  }*/








  void _verificarCondiciones() {
    bool condicionesCumplidas = selectedEquipoId != null &&
        selectedIncidenciaId != null &&
        emplazamientoController.text.split(' ').any((word) => word.length >= 4);
    setState(() {
      seccionHabilitada = condicionesCumplidas;
    });
  }








  // Función para ver el tipo de equip
  // Api02
  Future<void> verEquipo() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/listaTipoEquipo');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'selected_value': selectedEquipoId}),
      );








      print('Response Equipo: ${response.body}');
      print('Id Usuario aca: ${widget.userData.idUsuario}');
      print('Id Seccion aca: ${widget.userData.idSeccion}');








      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          equipoOptions = List<TipoEquipo>.from(data['result'].map((item) =>
              TipoEquipo(
                nombre: item['NOM_TIPO_UBICACION'].toString(),
                id: item['ID_TIPO_UBICACION'].toString(),
              )));
        });
        print('Equipo seleccionado - ID: $selectedEquipoId');
      } else {
        throw Exception('Failed to load equipo options');
      }
    } catch (error) {
      print('Error: $error');
    }
  }








  // Función para verificar el emplazamiento
  // Api04
  Future<void> verEmplazamineto() async {
    try {
      var emplazamiento = emplazamientoController.text.trim();
      if (emplazamiento.isEmpty) {
        mostrarError('Por favor, ingrese un emplazamiento');
        return;
      }








      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getValidaEmplazamiento');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'emplaz': emplazamiento,
          'idtipoubicacion': selectedEquipoId,
        }),
      );








      print('Response Emplazamiento: ${response.body}');








      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        estadoEmplazamiento = data['estado'];
        print('Estado: $estadoEmplazamiento');




        switch (estadoEmplazamiento) {
          case "-1":
            mostrarError('El emplazamiento no es válido');
            break;
          case "1":
            IdEmplazamiento = data['result']['ID_UBICACION'];
            print('Debo enviar los siguientes datos:');
            print(
                '(ID_TIPO_UBICACION obtenido en API04: $IdEmplazamiento');
            print(
                '(ID_TIPO_INCIDENCIA), seleccionado en el combo box del API03: $selectedIncidenciaId');
            print('(ID_TIPO_UBICACION), obtenido en API02: $selectedEquipoId');
            print(
                '(ID_USUARIO), obtenido en API01: ${widget.userData.idUsuario}');
            enviarRegistroIncidencia(); // Llamar a enviarRegistroIncidencia solo si el estado es 1
            break;
          default:
            mostrarError('Saliste de la App, vuelve a ingresar');
            break;
        }
      }
    } catch (error) {
      print('Verificar emplazamiento!: $error');
    }
  }












  // Función para ver el tipo de incidencia
  // Api03
  Future<void> verIncidencia() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/getListaTipoIncidencia');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idtipoubicacion': selectedEquipoId,
        }),
      );
      print('Response Incidencia: ${response.body}');












      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          incidenciaOptions = List<TipoEquipo>.from(data['result'].map((item) =>
              TipoEquipo(
                nombre: item['DESCRIPCION'].toString(),
                id: item['ID_TIPO_INCIDENCIA'].toString(),
              )));
          nombreIncidencia = incidenciaOptions;
          List<String> nombresInci = nombreIncidencia.map((equipo) => equipo.nombre).toList();








        });
        print('Estado: ${data['estado']}');
        print('Resultado: ${data['result']}');
      } else {
        throw Exception('Failed to load incidencia options');
      }
    } catch (error) {
      print('Error: $error');
      mostrarError('No hay conexión con el servidor');
    }
  }








  // Función para enviar el registro de la incidencia
  // Api05
  Future<void> enviarRegistroIncidencia() async {
    try {
      if (estadoEmplazamiento == '1') {
        var url = Uri.parse(
            'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/insertIncidencia');
        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'idubicacion': IdEmplazamiento,
            'idtipoincidencia': selectedIncidenciaId,
            'idtipoubicacion': selectedEquipoId,
            'idusuario': widget.userData.idUsuario,
          }),
        );




        print('Response enviar Registro Incidencia: ${response.body}');
        var data = json.decode(response.body);
        var estado = data['estado'];
        if(estado == 1) {
          var result = data['result'];
          var incidenciaId = result['ID_INCIDENCIA'];
          print('El número de incidencia: $incidenciaId');
          String formattedIncidenciaId = incidenciaId.padLeft(8, '0');
          registroCorrecto('Incidencia registrada con éxito. Código de Incidencia: $formattedIncidenciaId');
        }
      } else {
        print('El emplazamiento no es válido');
      }
    } catch (error) {
      print('Error en el registro de incidencia: $error');
      mostrarError('Error en el registro de incidencia: $error');
    }
  }




  // Función para cerrar la sesión
  // Api06
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
          registroCorrecto(msj);
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








  // Funcion para update Login
  // Api07
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








  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (widget.userData.idTipoUsuario == '8') {
        Navigator.pop(context);
        } else {
          // Muestra el diálogo para confirmar la salida de la aplicación
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Salir de la aplicación'),
                content: Text('¿Quieres salir de la aplicación?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      SystemNavigator.pop();
                      enviarCerrarSeccion();
                    },
                    child: Text('Sí'),
                  ),
                ],
              );
            },
          ) ?? false;


        }
        return false;
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
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Registro de incidencia',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
   


                const SizedBox(height: 20),
                // Selección de tipo de Equipo
                const Text('1.- Tipo de Equipo'),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: Container(
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedEquipoId ?? null,
                      icon: Icon(Icons.arrow_drop_down),
                      style:
                          const TextStyle(color: Colors.black, fontSize: 13),
                      underline: Container(
                        height: 0,
                        color: Colors.transparent,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedEquipoId = newValue;
                          selectedIncidenciaId = null;
                          verIncidencia();
                        });




                      },
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Center(child: Text('Seleccionar')),
                        ),
                        ...equipoOptions.map((TipoEquipo tipoEquipo) {
                          return DropdownMenuItem<String>(
                            value: tipoEquipo.id,
                            child: Center(child: Text(tipoEquipo.nombre)),
                          );
                        }).toList(),
                      ],
                      dropdownColor: Colors.grey[200],
                      elevation: 0,
                      isExpanded: true,
                      onTap: () {},
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Selecionar Tipo Incidencia
                const Text('2.- Tipo de Incidencia'),
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
                     
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        // Filtrar las opciones según lo que se haya escrito en el campo de texto
                        return incidenciaOptions
                            .where((option) => option.nombre
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()))
                            .map((option) => option.nombre)
                            .toList();
                      },
                      onSelected: (String selected) {
                        // Actualizar el valor seleccionado cuando se elige una opción del autocompletado
                        setState(() {
                          selectedIncidenciaId = incidenciaOptions
                              .firstWhere((option) => option.nombre == selected)
                              .id;
                        });
                        verIncidencia();
                      },
                      // Decoración para el campo de autocompletado
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Digite aquí',
                            hintStyle: TextStyle(
                              color: Colors.black,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        );
                      }
                    ),
                  ),
                ),
















                const SizedBox(height: 20),
                // Digitar Emplazamiento
                const Text('3.- Digite el emplazamiento del equipo'),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: Container(
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white,
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: emplazamientoController,
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Digite aquí',
                        hintStyle: TextStyle(
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onChanged: (_) => _verificarCondiciones(),
                    ),
                  ),
                ),








                ElevatedButton(
                  onPressed: seccionHabilitada
                      ? () {
                          enviarRegistroIncidencia();
                          verEmplazamineto();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Enviar incidencia',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
  /*
  @override
  void dispose() {
    emplazamientoController.dispose();
    // Llamar a la función para registrar la salida de la sesión
    enviarCerrarSeccion();
    super.dispose();
  }
  */




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








  // Función para mostrar diálogo de registro correcto
  void registroCorrecto(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera del diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registro Correcto'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                // Cerrar el diálogo actual
                Navigator.of(context).pop();
                mostrarDialogoPregunta();
              },
              child: const Text('Aceptar'),




            )
          ],
        );
      },
    );
  }






  // Función para mostrar diálogo de pregunta
  void mostrarDialogoPregunta() {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera del diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Quieres enviar más incidencias?'),
          actions: [
            // Si el usuario quiere enviar más incidencias, se reinician las variables de estado y se mantiene en la misma página
            TextButton(
              onPressed: () {
                // Reiniciar las variables de estado
                setState(() {
                  selectedEquipoId = null;
                  selectedIncidenciaId = null;
                  emplazamientoController.clear();
                  seccionHabilitada = false;
                });
                // Cerrar el diálogo actual
                Navigator.of(context).pop();
                // Navegar de vuelta a la vista para enviar más incidencias
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => EnviarPersonal(
                    usuario: widget.usuario,
                    contrasenia: widget.contrasenia,
                    userData: widget.userData,
                  ),
                ));
              },
              child: const Text('Sí'),
            ),
            // Si el usuario no quiere enviar más incidencias, se cierra el diálogo y se mantiene en la misma página
            TextButton(
              onPressed: () {
                // Cerrar el diálogo actual
                SystemNavigator.pop();
                // Enviar mensaje de cierre al usuario
                enviarCerrarSeccion();
              },
              child: const Text('No'),
            ),
          ],  
        );
      },
    );
  }
}





