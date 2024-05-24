import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_memories/listaInvitados.dart';
import 'package:gallery_memories/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gallery_memories/serviciosremotos.dart';
import 'package:gallery_memories/evento.dart';
import 'package:url_launcher/url_launcher.dart';


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
  //Controllers para cambiar los datos del usuario
  final username = TextEditingController();
  final nickname = TextEditingController();


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
        //Obtener los datos del usuario y almacenarlos en variables
        uid = user.uid;
        nombre_usuario = datosUsuario[0];
        abreviatura = datosUsuario[1];

        print("Tu usuario es:  $nombre_usuario");

        //Establecer los datos en los controllers de Mi perfil
        username.text = nombre_usuario;
        nickname.text = abreviatura;

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
      drawer:Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: FutureBuilder(
                future: Storage.obtenerURLimagen("profile_photos", "$uid.jpg"),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person, // Puedes cambiar este icono por el que desees
                            size: 60,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          nombre_usuario,
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(snapshot.data.toString()),
                        ),
                        SizedBox(height: 10),
                        Text(
                          nombre_usuario,
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    );
                  }
                },
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
            // Resto de elementos del Drawer
            _item(Icons.event, "MIS EVENTOS", 0),
            _item(Icons.mode_of_travel_outlined, "MIS INVITACIONES", 1),
            _item(Icons.add, "AGREGAR EVENTO", 2),
            _item(Icons.create_new_folder, "CREAR EVENTO", 3),
            _item(Icons.settings, "CONFIGURACIÓN", 4),
            _item(Icons.supervised_user_circle, "MI PERFIL", 5),
            _item(Icons.exit_to_app, "SALIR", 6),
          ],
        ),
      )
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
     case 5:
       return miPerfil();
     case 6 :
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
                        String primeraImagen = snapshot.data ?? '';
                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {//ABRIR VENTANA PARA MOSTRAR LOS DATOS DEL EVENTO
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => eventoIndividual(
                                    nombre: listaJSON.data?[indice]['nombre'] ?? '',
                                    tipoEvento: listaJSON.data?[indice]['tipoEvento'] ?? '',
                                    propietario: listaJSON.data?[indice]['propietario'] ?? '',
                                    idEvento: listaJSON.data?[indice]['id'] ?? '',
                                    isMine: true, //Como soy anfitrión, paso el valor directo de TRUE
                                    fechaEvento: listaJSON.data?[indice]['fechaEvento'] ?? '',
                                    horaEvento: listaJSON.data?[indice]['horaEvento'] ?? '',
                                    idUsuarioActual: uid,
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
                                  child: Image.network(
                                    primeraImagen.isNotEmpty
                                        ? primeraImagen
                                        : "https://img.freepik.com/vector-premium/icono-galeria-fotos-vectorial_723554-144.jpg?w=2000",
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
                                              onPressed: (){
                                                showDialog(
                                                    context: context,
                                                    builder: (context){
                                                      return AlertDialog(
                                                        title: Center(
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.warning_amber_outlined, color: Colors.red),
                                                              SizedBox(width: 8),
                                                              Text("Comprobar eliminación.", style: TextStyle(color: Colors.red)),
                                                            ],
                                                          ),
                                                        ),
                                                        content: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              "¿Está seguro de eliminar el evento  ${listaJSON.data?[indice]['nombre']}?",
                                                              style: TextStyle(fontSize: 16),
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              DB.eliminarEvento(listaJSON.data?[indice]['id']).then((value) {
                                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Evento ${listaJSON.data?[indice]['nombre']} borrado con éxito.")));
                                                              });
                                                              setState(() {});
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: Text("Aceptar"),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              // Usar la variable dialogContext en lugar de context
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: Text("Cancelar"),
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                );
                                              },
                                              icon: Icon(Icons.close, color: Colors.red,)
                                          ),
                                          SizedBox(width: 20,),
                                          IconButton(
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                    builder: (context) => listaInvitados(idEvento: listaJSON.data?[indice]['id'], nombreEvento: listaJSON.data?[indice]['nombre'],idUsuario: uid)
                                                ));
                                              },
                                              icon: Icon(Icons.checklist_rtl_sharp)
                                          ),
                                          SizedBox(width: 20,),
                                          //BOTÓN PARA COMPARTIR EL EVENTO
                                          IconButton(
                                              onPressed: (){
                                                void enviarMensajeWhatsApp() async {
                                                  String mensaje = Uri.encodeFull("${listaJSON.data?[indice]['id']}");
                                                  String telefono = '3221712894'; // Reemplaza esto con el número de teléfono al que deseas enviar el mensaje
                                                  String url = 'https://wa.me/?text=$mensaje';

                                                  if (await canLaunch(url)) {
                                                    await launch(url);
                                                  } else {
                                                    throw 'No se pudo abrir WhatsApp.';
                                                  }
                                                }
                                                enviarMensajeWhatsApp();
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
                        String primeraImagen = snapshot.data ?? '';
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
                                    idUsuarioActual: uid,
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
                                  child: Image.network(
                                    primeraImagen.isNotEmpty
                                        ? primeraImagen
                                        : "https://img.freepik.com/vector-premium/icono-galeria-fotos-vectorial_723554-144.jpg?w=2000",
                                    width: double.infinity,
                                    height: 130,
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
                                              //BOTON PARA ELIMINARME DE INVITADO DE ESTE EVENTO
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Center(
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.warning_amber_outlined, color: Colors.red),
                                                          SizedBox(width: 8),
                                                          Text("Comprobar eliminación.", style: TextStyle(color: Colors.red)),
                                                        ],
                                                      ),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          "¿Está seguro de eliminar el evento?",
                                                          style: TextStyle(fontSize: 16),
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          "${listaJSON.data?[indice]['nombre']}",
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          DB.eliminarInvitado("${listaJSON.data?[indice]['id']}", uid).then((value) {
                                                            setState(() {});
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saliste del evento ${listaJSON.data?[indice]['id']}")));
                                                          });
                                                          Navigator.of(context).pop();
                                                        },
                                                        child: Text("Aceptar"),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                        },
                                                        child: Text("Cancelar"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
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
                        isMine: false, //Como soy invitado paso un FALSE en este campo
                        fechaEvento: datosEvento['fechaEvento'] ?? '',
                        horaEvento: datosEvento['horaEvento'] ?? '',
                        idUsuarioActual: uid,
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
                //Crear evento y redireccionar a la ventana del evento creado
                DB.creaEvento(jsonTemporal).then((idEvento) async {
                  Map<String, dynamic> datosEvento = await DB.obtenerDatosEvento(idEvento);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => eventoIndividual(
                        nombre: datosEvento['nombre'] ?? '',
                        tipoEvento: datosEvento['tipoEvento'] ?? '',
                        propietario: datosEvento['propietario'] ?? '',
                        idEvento: datosEvento['id'] ?? '',
                        isMine: true, //Como soy invitado paso un FALSE en este campo
                        fechaEvento: datosEvento['fechaEvento'] ?? '',
                        horaEvento: datosEvento['horaEvento'] ?? '',
                        idUsuarioActual: uid,
                      ),
                    ),
                  );
                  setState(() {
                    nombre.text = "";
                    tipoEvento.text = "";
                    fechaEvento.text = "";
                    horaEvento.text = "";
                    _index = 0;
                  });
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
    return ListView(
        padding: EdgeInsets.all(30),
        children: [
      ElevatedButton(
          onPressed: (){
            showDialog(
                context: context,
                builder: (context){
                  return AlertDialog(
                    title: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Comprobar eliminación.", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "¿Está seguro de eliminar esta cuenta?",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          //Borrar todos los eventos del usuario
                          //Borrarse como invitado de todos los eventos en los que se encuentre
                          //Borrar datos del usuario (tabla usuarios
                          //La misma función elimina usuario hace todo
                          DB.eliminaUsuario(uid);
                          //Borrar usuario
                          User? user = FirebaseAuth.instance.currentUser;
                          await user?.delete();

                          //Salir al login
                          Future.delayed(Duration.zero, () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (builder) {
                                return login();
                              }),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("USUARIO ELIMINADO")));
                          });
                        },
                        child: Text("Aceptar"),
                      ),
                      TextButton(
                        onPressed: () {
                          // Usar la variable dialogContext en lugar de context
                          Navigator.of(context).pop();
                        },
                        child: Text("Cancelar"),
                      ),
                    ],
                  );
                }
            );
          },
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll<Color>(Colors.red),
          ),
          child: Text("BORRAR CUENTA")
      )
    ]
    );
  }

  Widget miPerfil(){
    return ListView(
      padding: EdgeInsets.all(30),
      children: [
        Center(
          child: Text("MI PERFIL", style: TextStyle(fontFamily: 'BebasNeue', fontSize: 30),),
        ),
        SizedBox(height: 20,),
        Container(
          child: FutureBuilder(
            future: Storage.obtenerURLimagen("profile_photos", "$uid.jpg"),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) { //NO EXISTE FOTO DE PERFIL
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage("https://cdn-icons-png.flaticon.com/512/9187/9187604.png"),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () async {
                                final fotoNueva = await FilePicker.platform.pickFiles(
                                    allowMultiple: false,
                                    type: FileType.custom,
                                    allowedExtensions: ['png', 'jpg', 'jpeg']
                                );

                                if (fotoNueva == null || fotoNueva.files.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No se ha seleccionado ninguna foto.")));
                                  return;
                                }

                                var path = fotoNueva.files.first.path!;
                                var nombre = "$uid.jpg";
                                var nombreCarpeta = "profile_photos";

                                Storage.subirFoto(path, nombre, nombreCarpeta).then((value) {
                                  setState(() {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("FOTO ACTUALIZADA CON ÉXITO!")));
                                  });
                                });

                                print("Botón '+' presionado");
                              },
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(snapshot.data.toString()),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () async {
                                final fotoNueva = await FilePicker.platform.pickFiles(
                                    allowMultiple: false,
                                    type: FileType.custom,
                                    allowedExtensions: ['png', 'jpg', 'jpeg']
                                );

                                if (fotoNueva == null || fotoNueva.files.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No se ha seleccionado ninguna foto.")));
                                  return;
                                }

                                var path = fotoNueva.files.first.path!;
                                var nombre = "$uid.jpg";
                                var nombreCarpeta = "profile_photos";

                                Storage.subirFoto(path, nombre, nombreCarpeta).then((value) {
                                  setState(() {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("FOTO ACTUALIZADA CON ÉXITO!")));
                                  });
                                });

                                print("Botón '+' presionado");
                              },
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
        SizedBox(height: 20,),
        TextField(
          controller: username,
          decoration: InputDecoration(
              labelText: "Nombre de usuario:", border: OutlineInputBorder()),
        ),
        SizedBox(
          height: 20,
        ),
        TextField(
          controller: nickname,
          decoration: InputDecoration(
              labelText: "Alias de tu usario:",
              border: OutlineInputBorder()),
        ),
        SizedBox(
          height: 20,
        ),
        ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cambios realizados")));
              setState(() {
                DB.actualizarDatosUsuario(uid, username.text, nickname.text).then((value){
                  setState(() {
                    this.nombre_usuario = username.text;
                    this.abreviatura = nickname.text;
                  });
                } );
              });
            },
            child: const Text("Guardar")),
      ],
    );
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

  // Función para mostrar la lista de invitados
  Future<void> mostrarListaInvitados(BuildContext context, String idEvento, String nombreEvento) async {
    // Obtener la lista de invitados
    List<dynamic> invitados = await DB.obtenerListaInvitados(idEvento);
    List<Widget> listaItems = [];

    for (var invitado in invitados) {
      String idInvitado = invitado['idInvitado'];
      String nombre = invitado['nombre'];
      bool tieneAcceso = invitado['acceso'];
      String subtitulo = tieneAcceso ? "Tiene acceso" : "No tiene acceso";

      // Agregar SwitchListTile a la lista de items
      listaItems.add(
        SwitchListTile(
          title: Text(nombre),
          subtitle: Text(subtitulo),
          value: tieneAcceso,
          onChanged: (bool value) async {
            // Actualizar el valor de acceso en la base de datos
            await DB.actualizarAccesoInvitado(idEvento, idInvitado, !tieneAcceso);

            // Actualizar la lista de invitados
            List<dynamic> nuevaListaInvitados = await DB.obtenerListaInvitados(idEvento);

            // Actualizar el estado del widget y reconstruir la interfaz de usuario
            setState(() {
              invitados = nuevaListaInvitados;
            });
          },
        ),
      );
    }

    // Mostrar el AlertDialog con la lista de invitados
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Invitados al evento \n"$nombreEvento" '),),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: listaItems,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
