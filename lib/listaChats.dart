import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_memories/serviciosremotos.dart';
import 'package:gallery_memories/chat.dart';

class listaChats extends StatefulWidget {
  final String idUsuario,nombre,nickname,usuarioActual;

  const listaChats({required this.idUsuario, required this.nombre, required this.nickname, required this.usuarioActual});

  @override
  State<listaChats> createState() => _listaChatsState();
}

class _listaChatsState extends State<listaChats> {
  Map<String, dynamic> _Chats = {};
  List<Map<String, dynamic>> _DatosChats = [];
  bool _isLoading = true;

  @override

  void initState() {
    super.initState();
    _cargarChats();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de chats"),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _DatosChats.isEmpty
                ? Center(child: Text('Aún no hay chats con amigos'))
                : ListView.builder(

              itemCount: _DatosChats.length,
              itemBuilder: (context, index) {
                var dato = _DatosChats[index];
                String nickname = dato['nickname'];
                String nombre = dato['nombre'];
                String correo = dato['correo'];
                String idPersona1 = dato['idPersona1'];
                String idPersona2 = dato['idPersona2'];
                String idChat = dato['idChat'];

                return ListTile(
                  title: Text(nombre+" -> "+nickname),
                  subtitle: Text(correo),
                  leading: Icon (Icons.group_sharp, color: Colors.green,),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat_sharp, color: Colors.black87,),
                        onPressed: () async{
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => chat(
                                    idChat: idChat,
                                    idPersona1: idPersona1,
                                    idPersona2: idPersona2,
                                    idUsuarioActual: idPersona1,
                                    nombre: nombre,
                                    nickname: nickname,),
                                ));
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.group_remove_sharp, color: Colors.red,),
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
                                        Text("Eliminación de chat.", style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "¿Está seguro de eliminar este chat?",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                          DB.eliminarChat(idChat);
                                          setState(() {
                                            super.dispose();
                                            _isLoading = false;
                                            _DatosChats.remove(dato);
                                          });
                                          _cargarChats();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chat eliminado")));
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
                );
              },
            ),
          )
        ],
      ),
    );
  }
  Future<void> _cargarChats() async {
    setState(() {
      _isLoading = true;
    });

    _Chats = await DB.obtenerChats(widget.idUsuario);

    setState(() {
      _DatosChats = _Chats['chats'].cast<Map<String, dynamic>>();
      _isLoading = false;
    });
  }
}