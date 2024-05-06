import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_memories/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gallery_memories/serviciosremotos.dart';
import 'package:gallery_memories/evento.dart';
class inicioApp extends StatefulWidget {
  const inicioApp({super.key});

  @override
  State<inicioApp> createState() => _inicioAppState();
}

class _inicioAppState extends State<inicioApp> {
  String abreviatura = "U", nombre_usuario = "User", uid = "";
  int _index = 0; //Para la navegación con el drawer
  List eventos = [
    "Bautizo",
    "Fiesta de cumpleaños",
    "Boda",
    "XV Años",
    "Primera comunión",
    "Graduación",
    "Reunión"
  ];
  String eventoSeleccionado = "";

  //Controllers para crear un evento
  final nombre = TextEditingController();
  final tipoEvento = TextEditingController();
  final fechaEvento = TextEditingController();
  final horaEvento = TextEditingController();
  final numInvitacion = TextEditingController();


  //Variables para consultar un evento como invitado
  String auxProp = "", auxFecha= "", auxHora = "", auxNombre = "", auxTipo = "";


  @override
  void setUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      print("Sesion iniciada con el ID: $uid");
      List<String> datosUsuario = await DB.recuperarDatos(uid);

      setState(() {
        uid = user.uid;
        nombre_usuario = datosUsuario[0];
        print("Tu usuario es:  $nombre_usuario");
        abreviatura = datosUsuario[1];
      });
    }
  }

  void initState() {
    setUser();
    super.initState();
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("GALLERY MEMORIES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500,),),
        centerTitle: true,
        backgroundColor: Colors.blue,
        shadowColor: Colors.grey,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3498DB),
                Color.fromARGB(256, 55, 199, 250),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: dinamico(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      abreviatura,
                      style: TextStyle(fontSize: 20, color: Colors.blue),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    nombre_usuario,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  )
                ],
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4C60AF),
                    Color.fromARGB(255, 37, 195, 248),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            _item(Icons.event, "MIS EVENTOS", 0),
            _item(Icons.mode_of_travel_outlined, "MIS INVITACIONES", 1),
            _item(Icons.add, "AGREGAR EVENTO", 2),
            _item(Icons.create_new_folder, "CREAR EVENTO", 3),
            _item(Icons.settings, "CONFIGURACIÓN", 4),
            _item(Icons.exit_to_app, "SALIR", 5),
          ],
        ),
      ),

    );
  }


  Widget _item(IconData icono, String texto, int indice) {
    return ListTile(
      onTap: () {
        setState(() {
          _index = indice;
        });
        Navigator.pop(context);
      },
      title: Row(
        children: [
          Expanded(child: Icon(icono)),
          Expanded(
            child: Text(texto),
            flex: 3,
          )
        ],
      ),
    );
  }

  Widget dinamico(){
   switch (_index){
     case 0:
       return misEventos();
     case 1:
       return invitaciones();
     case 2:
       return agregarEvento();
     case 3:
       return crearEvento();
     case 4:
       return configuracion();
     case 5 :
       //Navegar a la pantalla del login (cerrar sesión)
       Future.delayed(Duration.zero, () {
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(builder: (builder) {
             return login();
           }),
         );
       });
   }
   return misEventos();
  }

  Widget misEventos(){
    return FutureBuilder(
      future: DB.obtenerEventos(uid),
      builder: (context, listaJSON) {
        if (listaJSON.hasData) {
          print("Eventos encontrados: ${listaJSON.data} para el usuario $uid");
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30),
              Text(
                "MIS EVENTOS",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 40,
                  fontFamily: 'BebasNeue',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: listaJSON.data?.length,
                  itemBuilder: (context, indice) {
                    return FutureBuilder(
                      future: Storage.obtenerPrimeraImagenDeAlbum('${listaJSON.data?[indice]['id']}',),
                      builder: (context, snapshot) {
                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              //ABRIR VENTANA PARA MOSTRAR LOS DATOS DEL EVENTO
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => eventoIndividual(
                                    nombre: listaJSON.data?[indice]['nombre'] ?? '',
                                    tipoEvento: listaJSON.data?[indice]['tipoEvento'] ?? '',
                                    propietario: listaJSON.data?[indice]['propietario'] ?? '',
                                    idEvento: listaJSON.data?[indice]['id'] ?? '',
                                    isMine: listaJSON.data?[indice]['propietario'] == uid,
                                    fechaEvento: listaJSON.data?[indice]['fechaEvento'] ?? '',
                                    horaEvento: listaJSON.data?[indice]['horaEvento'] ?? '',
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  ),
                                  child: Image.network("https://img.freepik.com/vector-premium/icono-galeria-fotos-vectorial_723554-144.jpg?w=2000",
                                    width: double.infinity,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        listaJSON.data?[indice]['nombre'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${listaJSON.data?[indice]['tipoEvento']}",
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          //BOTON PARA COPIAR CÓDIGO DE INVITACIÓN
                                          IconButton(
                                              onPressed: (){
                                                // Copia el código de invitación al portapapeles
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: "${listaJSON.data?[indice]['id']}",
                                                  ),
                                                );

                                                // Muestra un mensaje emergente para informar al usuario que el código ha sido copiado
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Código de invitación copiado al portapapeles."),),);
                                              },
                                              icon: Icon(Icons.copy, color: Colors.black87,)
                                          ),
                                          //BOTÓN PARA ELIMINAR EL EVENTO
                                          SizedBox(width: 20,),
                                          IconButton(
                                              onPressed: (){},
                                              icon: Icon(Icons.close, color: Colors.red,)
                                          ),
                                          SizedBox(width: 20,),
                                          //BOTÓN PARA COMPARTIR EL EVENTO
                                          IconButton(
                                              onPressed: (){
                                                //Buscar COMPONENTE PARA ENVIAR MSJ POR WHATSAPP
                                                //compartirTexto("Hola! Me gustaría que te unieras a mi album en Gallery Memories. Ingresa el código ${listaJSON.data?[indice]['id']} en Agregar Evento");
                                              },
                                              icon: Icon(Icons.share, color: Colors.blueGrey,)
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget invitaciones(){
    return FutureBuilder(
      future: DB.misInvitaciones(uid),
      builder: (context, listaJSON) {
        if (listaJSON.hasData && listaJSON.data != null) {
          print("Invitaciones encontradas: ${listaJSON.data} para el usuario $uid");
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30),
              Text(
                "MIS INVITACIONES",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 40,
                  fontFamily: 'BebasNeue',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: listaJSON.data?.length,
                  itemBuilder: (context, indice) {
                    return FutureBuilder(
                      future: Storage.obtenerPrimeraImagenDeAlbum('${listaJSON.data?[indice]['id']}',),
                      builder: (context, snapshot) {
                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => eventoIndividual(
                                    nombre: listaJSON.data?[indice]['nombre'] ?? '',
                                    tipoEvento: listaJSON.data?[indice]['tipoEvento'] ?? '',
                                    propietario: listaJSON.data?[indice]['propietario'] ?? '',
                                    idEvento: listaJSON.data?[indice]['id'] ?? '',
                                    isMine: listaJSON.data?[indice]['propietario'] == uid,
                                    fechaEvento: listaJSON.data?[indice]['fechaEvento'] ?? '',
                                    horaEvento: listaJSON.data?[indice]['horaEvento'] ?? '',
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mostrar la primera imagen si está disponible, de lo contrario, mostrar la imagen genérica
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  ),
                                  child: Image.network("https://img.freepik.com/vector-premium/icono-galeria-fotos-vectorial_723554-144.jpg?w=2000",
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listaJSON.data?[indice]['nombre'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${listaJSON.data?[indice]['tipoEvento']}",
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                            },
                                            icon: Icon(Icons.close, color: Colors.red,),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget agregarEvento(){
    return ListView(
      padding: EdgeInsets.all(40),
      children: [
        Center(
          child: Text(
            "AGREGAR EVENTO",
            style: TextStyle(
              fontSize: 25,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: numInvitacion,
          decoration: InputDecoration(
            labelText: "CÓDIGO DE INVITACION:",
            border: OutlineInputBorder(),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: Icon(Icons.event),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              List<dynamic> jsonTemporal = await DB.buscarInvitacion(numInvitacion.text);
              setState(() {
                auxProp = "Realizado por: ${jsonTemporal[0]['propietario']}";
                auxNombre = "Nimbre: ${jsonTemporal[0]['nombre']}";
                auxFecha = "Fecha: ${jsonTemporal[0]['fechaEvento']}";
                auxHora = "Hora: ${jsonTemporal[0]['horaEvento']}";
                auxTipo = "Tipo de evento: ${jsonTemporal[0]['tipoEvento']}";
              });
            } catch (error) {
              print("Error al buscar invitación: $error");
              // Puedes mostrar un mensaje de error al usuario si es necesario
            }
          },
          child: Text("CONSULTAR EVENTO"),
        ),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${auxProp}", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
              SizedBox(height: 8.0),
              Text("$auxNombre", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
              SizedBox(height: 8.0),
              Text("$auxFecha", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
              SizedBox(height: 8.0),
              Text("$auxHora", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
              SizedBox(height: 8.0),
              Text("$auxTipo", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              bool invitadoAgregado = await DB.agregarInvitado(numInvitacion.text, uid);
              if (invitadoAgregado) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Evento agregado")));
                setState(() {
                  _index = 1;
                });
                // Obtener los datos del evento desde Firebase usando el ID del evento
                Map<String, dynamic> datosEvento = await DB.obtenerDatosEvento(numInvitacion.text);
                if (datosEvento != null) {
                  // Navegar a la ventana eventoIndividual con los datos del evento
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => eventoIndividual(
                        nombre: datosEvento['nombre'] ?? '',
                        tipoEvento: datosEvento['tipoEvento'] ?? '',
                        propietario: datosEvento['propietario'] ?? '',
                        idEvento: datosEvento['id'] ?? '',
                        isMine: datosEvento['propietario'] == uid,
                        fechaEvento: datosEvento['fechaEvento'] ?? '',
                        horaEvento: datosEvento['horaEvento'] ?? '',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: No se pudieron obtener los datos del evento.")));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Solo puedes añadirte como invitado a eventos de otros usuarios.")));
              }
              setState(() {
                numInvitacion.text = "";
                auxProp = "";
                auxFecha = "";
                auxHora = "";
                auxNombre = "";
                auxTipo = "";
              });
            } catch (error) {
              print("Error al agregar invitado: $error");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al agregar invitado. Por favor, inténtalo de nuevo más tarde.")));
            }
          },
          child: Text("INGRESAR"),
        ),

      ],
    );
  }

  Widget crearEvento(){
    return ListView(
      padding: EdgeInsets.all(40),
      children: [
        Center(
          child: Text(
            "EVENTO NUEVO",
            style: TextStyle(
                fontSize: 25, color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20,),
        TextField(
          controller: nombre,
          decoration: InputDecoration(
              labelText: "NOMBRE",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always),
        ),
        SizedBox(
          height: 15,
        ),
        DropdownButtonFormField(
          value: eventos.first,
          items: eventos.map((e) {
            return DropdownMenuItem(
              child: Text(e),
              value: e,
            );
          }).toList(),
          onChanged: (item) {
            setState(() {
              eventoSeleccionado = item.toString();
              tipoEvento.text = eventoSeleccionado;
            });
          },
          decoration: InputDecoration(
              labelText: "TIPO DE EVENTO",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always),
        ),
        SizedBox(height: 15,),
        TextField(
          controller: fechaEvento,
          decoration: InputDecoration(
              labelText: "FECHA DEL EVENTO",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always),
          textAlign: TextAlign.center,
          readOnly: true,
          onTap: () {
            _selectDate(fechaEvento);
          },
        ),
        SizedBox(height: 15,),
        TextField(
          controller: horaEvento,
          decoration: InputDecoration(
              labelText: "HORA",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always),
          textAlign: TextAlign.center,
          readOnly: true,
          onTap: () {
            _selectTime(horaEvento);
          },
        ),
        SizedBox(height: 15,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                User? user = FirebaseAuth.instance.currentUser;
                var jsonTemporal = {
                  'propietario': user?.uid.toString(),
                  'nombre': nombre.text,
                  'tipoEvento': tipoEvento.text,
                  'fechaEvento': fechaEvento.text,
                  'horaEvento': horaEvento.text,
                  'estatus': true,
                  'invitados': [],
                };

                DB.creaEvento(jsonTemporal).then((idEvento) {
                  setState(() {
                    nombre.text = "";
                    tipoEvento.text = "";
                    fechaEvento.text = "";
                    horaEvento.text = "";
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("TU EVENTO SE CREÓ CON ÉXITO!")));
                });
              },
              child: Text("Crear"),
            ),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    _index = 0;
                  });
                },
                child: Text("Cancelar")),
          ],
        )
      ],
    );
  }

  Widget configuracion(){
    return Center(child: Text("PESTAÑA CONFIGURACION"),);
  }

// Componente para seleccionar fecha en formato DD/Mes/YYYY
  Future<void> _selectDate(TextEditingController controlador) async {
    // Lista de nombres de meses en español
    final List<String> _meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    // Mostrar el selector de fecha
    DateTime? _picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    // Si el usuario selecciona una fecha
    if (_picked != null) {
      // Formatear la fecha seleccionada en formato DD/Mes/YYYY
      String day = _picked.day.toString().padLeft(2, '0'); // Añade un cero al día si es necesario
      String month = _meses[_picked.month - 1]; // Obtiene el nombre del mes
      String year = _picked.year.toString(); // Obtiene el año
      String formattedDate = '$day/$month/$year';

      // Actualizar el estado del controlador de texto con la fecha seleccionada
      setState(() {
        controlador.text = formattedDate;
      });
    }
  }

// Componente para seleccionar hora en formato de 12 horas
  Future<void> _selectTime(TextEditingController controlador) async {
    // Mostrar el selector de hora
    TimeOfDay? _picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(), // Hora inicial es la hora actual
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    // Si el usuario selecciona una hora
    if (_picked != null) {
      // Convertir la hora seleccionada a formato de 12 horas
      String formattedTime = _formatTime(_picked.hour, _picked.minute);

      // Actualizar el estado del controlador de texto con la hora seleccionada
      setState(() {
        controlador.text = formattedTime;
      });
    }
  }

// Función para formatear la hora en formato de 12 horas
  String _formatTime(int hour, int minute) {
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      hour = hour % 12;
    }
    if (hour == 0) {
      hour = 12;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
