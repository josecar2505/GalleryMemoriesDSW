import 'package:flutter/material.dart';
import 'package:gallery_memories/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gallery_memories/serviciosremotos.dart';


class inicioApp extends StatefulWidget {
  const inicioApp({super.key});

  @override
  State<inicioApp> createState() => _inicioAppState();
}

class _inicioAppState extends State<inicioApp> {
  String abreviatura = "U", nombre_usuario = "User", uid = "";
  int _index = 0;

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
    return Center(child: Text("PESTAÑA MIS EVENTOS"),);
  }

  Widget invitaciones(){
    return Center(child: Text("PESTAÑA MIS INVITACIONES"),);
  }

  Widget agregarEvento(){
    return Center(child: Text("PESTAÑA AGREGAR EVENTO"),);
  }

  Widget crearEvento(){
    return Center(child: Text("PESTAÑA CREAR EVENTO"),);
  }

  Widget configuracion(){
    return Center(child: Text("PESTAÑA CONFIGURACION"),);
  }
}
