import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_memories/serviciosremotos.dart';

class bandejaComentarios extends StatefulWidget {
  String idEvento, nombreImagen, idUsuarioActual;
  final bool isMine;
  bandejaComentarios({required this.idEvento, required this.nombreImagen, required this.idUsuarioActual, required this.isMine,});

  @override
  State<bandejaComentarios> createState() => _BandejaComentariosState();
}

class _BandejaComentariosState extends State<bandejaComentarios> {
  List<Map<String, dynamic>> _comentarios = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _filtrarMisComentarios = false;
  bool _filtrarSoloMisComentarios = false;

  @override
  void initState() {
    super.initState();
    _cargarComentarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comentarios"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child:
              PopupMenuButton<String>(
                child: Icon(Icons.filter_alt_rounded),
                onSelected: (value) {
                  if (value == 'Mis comentarios primero') {
                    _toggleFiltroMisComentarios();
                  }else if (value == 'Solo mis comentarios'){
                    _toggleFiltroSoloMisComentarios();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return {'Mis comentarios primero', 'Solo mis comentarios'}.map((String choice) {
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
                : _comentarios.isEmpty
                ? Center(child: Text('Aún no hay comentarios'))
                : ListView.builder(
                    itemCount: _comentarios.length,
                    itemBuilder: (context, index) {
                      var comentario = _comentarios[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 2.0,
                          child: ListTile(
                            title: Text(
                              comentario['nombreUsuario'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comentario['comentario']),
                                SizedBox(height: 5),
                                Text(
                                  '${_formatearFecha(comentario['timestamp'])}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: (widget.isMine || comentario['usuario'] == widget.idUsuarioActual)
                                ? _buildPopupMenuButton(comentario)
                                : null,
                          ),
                        ),
                      );
                    },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _commentInputField(),
          ),
        ],
      ),
    );
  }

  Widget _commentInputField() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Escribe un comentario...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _agregarComentario,
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> comentario) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'Editar') {
          _editarComentario(comentario);
        } else if (value == 'Eliminar') {
          _eliminarComentario(comentario['id']);
        }
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          if (comentario['usuario'] == widget.idUsuarioActual)
            PopupMenuItem<String>(
              value: 'Editar',
              child: Text('Editar'),
            ),
          if (widget.isMine || comentario['usuario'] == widget.idUsuarioActual)
            PopupMenuItem<String>(
              value: 'Eliminar',
              child: Text('Eliminar'),
            ),
        ];
      },
    );
  }

  Future<void> _cargarComentarios() async {
    try {
      var comentarios = await DB.obtenerComentarios(widget.idEvento, widget.nombreImagen);
      setState(() {
        _comentarios = comentarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
    print(_comentarios);
  }

  Future<void> _agregarComentario() async {
    if (_commentController.text.isNotEmpty) {
      await DB.agregarComentario(widget.idEvento, widget.nombreImagen, _commentController.text, widget.idUsuarioActual);
      _commentController.clear();
      _cargarComentarios(); // Recargar comentarios después de agregar uno nuevo
    }
  }

  Future<void> _eliminarComentario(String idComentario) async {
    print(idComentario);
    await DB.eliminarComentario(widget.idEvento, widget.nombreImagen, idComentario);
    _cargarComentarios();
  }

  Future<void> _editarComentario(Map<String, dynamic> comentario) async {
    TextEditingController _editController = TextEditingController(text: comentario['comentario']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Editar Comentario"),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(hintText: "Editar comentario"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_editController.text.isNotEmpty) {
                  await DB.editarComentario(widget.idEvento, widget.nombreImagen, comentario['id'], _editController.text);
                  _cargarComentarios();
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

  void _toggleFiltroMisComentarios() async {
    _filtrarMisComentarios = !_filtrarMisComentarios;
    print("Filtrar mis comentarios: $_filtrarMisComentarios");
    if (_filtrarMisComentarios) {
      setState(() {
        _comentarios.sort((a, b) {
          if (a['usuario'] == widget.idUsuarioActual && b['usuario'] != widget.idUsuarioActual) {
            print("Mover comentario del usuario actual al principio: $a");
            return -1; // Mover el comentario hecho por el usuario actual al principio
          } else if (a['usuario'] != widget.idUsuarioActual && b['usuario'] == widget.idUsuarioActual) {
            print("Mover comentario hecho por otro usuario después del comentario del usuario actual: $a");
            return 1; // Mover el comentario hecho por otro usuario después del comentario del usuario actual
          }
          return 0; // Mantener el orden original para otros comentarios
        });
      });
    } else {
      // Si el filtro está desactivado, vuelve a cargar los comentarios originales
      _cargarComentarios();
    }
  }

  void _toggleFiltroSoloMisComentarios() async {
    _filtrarSoloMisComentarios = !_filtrarSoloMisComentarios;
    print("Filtrar solo mis comentarios: $_filtrarSoloMisComentarios");
    if (_filtrarSoloMisComentarios) {
      setState(() {
        _comentarios = _comentarios.where((comentario) => comentario['usuario'] == widget.idUsuarioActual).toList();
      });
    } else {
      // Si el filtro está desactivado, vuelve a cargar los comentarios originales
      _cargarComentarios();
    }
  }
}
