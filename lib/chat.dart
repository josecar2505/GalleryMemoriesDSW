import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_memories/serviciosremotos.dart';

class chat extends StatefulWidget {
  String idChat, idPersona1, idPersona2, idUsuarioActual,nombre,nickname;

  chat({required this.idChat, required this.idPersona1, required this.idPersona2, required this.idUsuarioActual, required this.nombre, required this.nickname});

  @override
  State<chat> createState() => _chatState();
}

class _chatState extends State<chat> {
  List<dynamic> _mensajes = [];
  final TextEditingController _mensajeController = TextEditingController();
  bool _isLoading = true;
  bool _filtrarMisMensajes = false;
  bool _filtrarSoloMisMensajes = false;

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mensajes"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child:
            PopupMenuButton<String>(
              child: Icon(Icons.filter_alt_rounded),
              onSelected: (value) {
                if (value == 'Mis mensajes primero') {
                  _toggleFiltroMisMensajes();
                }else if (value == 'Solo mis mensajes'){
                  _toggleFiltroSoloMisMensajes();
                }
              },
              itemBuilder: (BuildContext context) {
                return {'Mis mensajes primero', 'Solo mis mensajes'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                ? Center(child: Text('Aun no hay mensajes en el chat'))
                : ListView.builder(
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                var mensajes = _mensajes[index];
                bool esMio = false;
                if(mensajes['usuario'] == widget.idUsuarioActual){
                  esMio = true;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 2.0,
                    color: esMio ? Colors.tealAccent : Colors.white70,
                    child: ListTile(

                      title: Text(
                        mensajes['nombre']+" -> "+mensajes['nickname'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mensajes['comentario']),
                          SizedBox(height: 5),
                          Text(
                            '${_formatearFecha(mensajes['timestamp'])}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: (mensajes['usuario'] == widget.idUsuarioActual)
                          ? _buildPopupMenuButton(mensajes)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _mensajeInputField(),
          ),
        ],
      ),
    );
  }

  Widget _mensajeInputField() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _mensajeController,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _agregarMensaje,
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> mensajes) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'Editar') {
          _editarMensaje(mensajes);
        } else if (value == 'Eliminar') {
          _eliminarMensaje(mensajes['timestamp'],widget.idChat);
        }
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          if (mensajes['usuario'] == widget.idUsuarioActual)
            PopupMenuItem<String>(
              value: 'Editar',
              child: Text('Editar'),
            ),
          if (mensajes['usuario'] == widget.idUsuarioActual)
            PopupMenuItem<String>(
              value: 'Eliminar',
              child: Text('Eliminar'),
            ),
        ];
      },
    );
  }

  Future<void> _cargarMensajes() async {
    try {
      var mensajes = await DB.obtenerMensajes(widget.idChat);
      setState(() {
        _mensajes = mensajes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _agregarMensaje() async {
    if (_mensajeController.text.isNotEmpty) {
      await DB.agregarMensaje(widget.idChat, _mensajeController.text, widget.idUsuarioActual,widget.nombre,widget.nickname);
      _mensajeController.clear();
      _cargarMensajes(); // Recargar comentarios después de agregar uno nuevo
    }
  }

  Future<void> _eliminarMensaje(Fecha, idChat) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar mensaje"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "¿Está seguro de eliminar este mensaje?",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await DB.eliminarMensaje(idChat, Fecha);
                _cargarMensajes();
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
  }

  Future<void> _editarMensaje(Map<String, dynamic> mensaje) async {
    TextEditingController _editController = TextEditingController(text: mensaje['comentario']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Editar mensaje"),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(hintText: "Editar mensaje"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_editController.text.isNotEmpty) {
                  await DB.editarMensaje(widget.idChat,mensaje['timestamp'],_editController.text);
                  _cargarMensajes();
                  Navigator.of(context).pop();
                }
              },
              child: Text("Guardar"),
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
  }


  DateTime _formatearFecha(Timestamp timestamp) {
    var date = timestamp.toDate();
    return date;
  }

  void _toggleFiltroMisMensajes() async {
    _filtrarMisMensajes = !_filtrarMisMensajes;
    print("Filtrar mis mensajes: $_filtrarMisMensajes");
    if (_filtrarMisMensajes) {
      setState(() {
        _mensajes.sort((a, b) {
          if (a['usuario'] == widget.idUsuarioActual && b['usuario'] != widget.idUsuarioActual) {
            print("Mover mensaje del usuario actual al principio: $a");
            return -1; // Mover el comentario hecho por el mensaje actual al principio
          } else if (a['usuario'] != widget.idUsuarioActual && b['usuario'] == widget.idUsuarioActual) {
            print("Mover mensaje hecho por otro usuario después del mensaje del usuario actual: $a");
            return 1; // Mover el mensaje hecho por otro usuario después del mensaje del usuario actual
          }
          return 0; // Mantener el orden original para otros mensajes
        });
      });
    } else {
      // Si el filtro está desactivado, vuelve a cargar los mensajes originales
      _cargarMensajes();
    }
  }

  void _toggleFiltroSoloMisMensajes() async {
    _filtrarSoloMisMensajes = !_filtrarSoloMisMensajes;
    print("Filtrar solo mis comentarios: $_filtrarSoloMisMensajes");
    if (_filtrarSoloMisMensajes) {
      setState(() {
        _mensajes = _mensajes.where((mensaje) => mensaje['usuario'] == widget.idUsuarioActual).toList();
      });
    } else {
      // Si el filtro está desactivado, vuelve a cargar los mensajes originales
      _cargarMensajes();
    }
  }
}