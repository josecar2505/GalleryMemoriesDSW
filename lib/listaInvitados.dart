import 'package:flutter/material.dart';
import 'package:gallery_memories/serviciosremotos.dart';
class listaInvitados extends StatefulWidget {
  final String idEvento;
  final String nombreEvento;
  final String idUsuario;

  const listaInvitados({required this.idEvento, required this.nombreEvento,required this.idUsuario});

  @override
  State<listaInvitados> createState() => _listaInvitadosState();
}

class _listaInvitadosState extends State<listaInvitados> {
  List<Map<String, dynamic>> _invitados = [];
  List<Map<String, dynamic>> _amigos = [];
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _invitados.isEmpty
                ? Center(child: Text('Aún no hay invitados'))
                : ListView.builder(
              itemCount: _invitados.length,
              itemBuilder: (context, index) {
                var invitado = _invitados[index];
                List<Map<String, dynamic>> amigos = _amigos;
                String idInvitado = invitado['idInvitado'];
                String nombre = invitado['nombre'];
                bool tieneAcceso = invitado['acceso'];
                bool amigoValido = false;
                String subtitulo = tieneAcceso
                    ? "Tiene acceso"
                    : "No tiene acceso";
                amigos.forEach((amigo) {
                  if(amigo.containsValue(idInvitado)){
                    amigoValido = true;
                  }
                });

                return ListTile(
                  title: Text(nombre),
                  subtitle: Text(subtitulo),
                  trailing: Switch(
                    value: tieneAcceso,
                    onChanged: (bool value) async {
                      await DB.actualizarAccesoInvitado(
                          widget.idEvento, idInvitado, value);
                      _cargarInvitados();
                    },
                  ),
                  leading: IconButton (
                    icon: Icon(
                      Icons.person,
                      color: amigoValido ? Colors.green : Colors.blue,
                    ),
                    onPressed: () async{
                      await DB.agregarAmigo(widget.idUsuario, idInvitado).then((value){
                        value ? (ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usuario "+nombre+" ha sido agregado como amigo"))), (_cargarInvitados())) :
                        (ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usuario "+nombre+" no es posible agregarlo como amigo, puede que ya lo tengas"))));
                      });
                    }),
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
    List<dynamic> amigos = await DB.Amigos(widget.idUsuario);
    setState(() {
      _invitados = invitados.cast<Map<String, dynamic>>();
      _amigos = amigos.cast<Map<String, dynamic>>();
      _isLoading = false;
    });
  }

}
