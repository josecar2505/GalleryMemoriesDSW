import 'package:flutter/material.dart';
import 'package:gallery_memories/serviciosremotos.dart';
class listaInvitados extends StatefulWidget {
  final String idEvento;
  final String nombreEvento;

  const listaInvitados({required this.idEvento, required this.nombreEvento});

  @override
  State<listaInvitados> createState() => _listaInvitadosState();
}

class _listaInvitadosState extends State<listaInvitados> {
  List<Map<String, dynamic>> _invitados = [];
  bool _isLoading = true;
  @override

  void initState() {
    super.initState();
    _cargarInvitados();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Invitados"),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading ? Center(child: CircularProgressIndicator()) : _invitados.isEmpty
                ? Center(child: Text('Aún no hay invitados'))
                : ListView.builder(
                    itemCount: _invitados.length,
                    itemBuilder: (context, index) {
                      var invitado = _invitados[index];
                      String idInvitado = invitado['idInvitado'];
                      String nombre = invitado['nombre'];
                      bool tieneAcceso = invitado['acceso'];
                      String subtitulo = tieneAcceso ? "Tiene acceso" : "No tiene acceso";

                      return ListTile(
                        title: Text(nombre),
                        subtitle: Text(subtitulo),
                        trailing: Switch(
                          value: tieneAcceso,
                          onChanged: (bool value) async {
                            await DB.actualizarAccesoInvitado(widget.idEvento, idInvitado, value);
                            _cargarInvitados();
                          },
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Future<void> _cargarInvitados() async {

    setState(() {
      _isLoading = true;
    });
    List<dynamic> invitados = await DB.obtenerListaInvitados(widget.idEvento);
    setState(() {
      _invitados = invitados.cast<Map<String, dynamic>>();
      _isLoading = false;
    });
  }
}
