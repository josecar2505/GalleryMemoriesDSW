import 'package:flutter/material.dart';
import 'package:gallery_memories/serviciosremotos.dart';
class listaAmigos extends StatefulWidget {
  final String idUsuario;

  const listaAmigos({required this.idUsuario});

  @override
  State<listaAmigos> createState() => _listaAmigosState();
}

class _listaAmigosState extends State<listaAmigos> {
  List<Map<String, dynamic>> _DatosAmigos = [];
  List<dynamic> datosamigos = [];
  List<dynamic> amigos = [];
  bool _isLoading = true;

  @override

  void initState() {
    super.initState();
    _cargarAmigos();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Amigos"),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _DatosAmigos.isEmpty
                ? Center(child: Text('Aún no hay amigos'))
                : ListView.builder(

              itemCount: _DatosAmigos.length,
              itemBuilder: (context, index) {
                var dato = _DatosAmigos[index];
                String nickname = dato['nickname'];
                String nombre = dato['nombre'];
                String correo = dato['correo'];
                String idUsuario = dato['idUsuario'];

                return ListTile(
                  title: Text(nombre),
                  subtitle: Text(correo),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat_sharp, color: Colors.black87,),
                        onPressed: () {

                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.person_remove_sharp, color: Colors.red,),
                        onPressed: () {
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
                                        Text("Eliminación de amigo.", style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "¿Está seguro de eliminar este usuario de tu lista de amigos?",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                          DB.eliminarAmigo(widget.idUsuario,idUsuario);
                                          //Borrar usuario de amigos
                                          setState(() {
                                            super.dispose();
                                            _isLoading = false;
                                            datosamigos.remove(dato);
                                          });
                                          _cargarAmigos();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usuario "+nickname+" eliminado de mi lista de amigos")));
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
                      ),
                    ],
                  ),

                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon (Icons.person, color: Colors.green,),
                      Text(nickname),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
  Future<void> _cargarAmigos() async {
    setState(() {
      _isLoading = true;
    });

    amigos = await DB.Amigos(widget.idUsuario);

    print(amigos);
    for(var usuario in amigos){
      datosamigos.add(await DB.obtenerDatosUsuario(usuario['amigos']));
    }
    print(datosamigos);
    setState(() {
      _DatosAmigos = datosamigos.cast<Map<String, dynamic>>();
      _isLoading = false;
    });
  }
}
