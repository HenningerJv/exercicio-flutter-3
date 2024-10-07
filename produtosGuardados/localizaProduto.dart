import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => LoginPage(),
      '/import': (context) => ImportaPage(),
      '/select': (context) => SelecionaProdutoPage(),
    },
  ));
}

class LoginPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu e-mail';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Senha"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Simular login e navegar para a tela de importação de produtos
                    Navigator.pushReplacementNamed(context, '/import');
                  }
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImportaPage extends StatefulWidget {
  @override
  _ImportaPageState createState() => _ImportaPageState();
}

class _ImportaPageState extends State<ImportaPage> {
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  // Inicializa o banco SQLite
  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'produtos.db'),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE produtos(idProduto INTEGER PRIMARY KEY, nome TEXT, precoVenda REAL)",
        );
      },
    );
  }

  // Função para buscar dados da API e armazenar no SQLite
  Future<void> _importProducts() async {
    final response = await http.get(Uri.parse('https://fakeapi.com/produtos'));
    if (response.statusCode == 200) {
      List<dynamic> produtos = json.decode(response.body);

      produtos.forEach((produto) async {
        await _database?.insert('produtos', {
          'idProduto': produto['idProduto'],
          'nome': produto['nome'],
          'precoVenda': produto['precoVenda'],
        });
      });

      ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text("Produtos importados com sucesso!")));
    } else {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text("Erro ao importar produtos")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Importar Produtos")),
      body: Center(
        child: ElevatedButton(
          onPressed: _importProducts,
          child: Text('Importar Produtos'),
        ),
      ),
    );
  }
}

class SelecionaProdutoPage extends StatefulWidget {
  @override
  _SelecionaProdutoPageState createState() => _SelecionaProdutoPageState();
}

class _SelecionaProdutoPageState extends State<SelecionaProdutoPage> {
  Database? _database;
  List<Map<String, dynamic>> _produtos = [];
  int _selectedProductId = 0;
  int _quantity = 1;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  // Inicializa o banco e carrega os produtos
  Future<void> _initializeDatabase() async {
    _database = await openDatabase(join(await getDatabasesPath(), 'produtos.db'));
    final List<Map<String, dynamic>> produtos = await _database!.query('produtos');
    setState(() {
      _produtos = produtos;
    });
  }

  // Atualiza o preço total
  void _atualizaTotalPreco() {
    if (_selectedProductId != 0) {
      final produto = _produtos.firstWhere((p) => p['idProduto'] == _selectedProductId);
      setState(() {
        _totalPrice = produto['precoVenda'] * _quantity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Selecionar Produto")),
      body: Column(
        children: [
          DropdownButton<int>(
            hint: Text("Selecione um Produto"),
            value: _selectedProductId == 0 ? null : _selectedProductId,
            onChanged: (value) {
              setState(() {
                _selectedProductId = value!;
              });
              _atualizaTotalPreco();
            },
            items: _produtos.map((produto) {
              return DropdownMenuItem<int>(
                value: produto['idProduto'],
                child: Text(produto['nome']),
              );
            }).toList(),
          ),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Quantidade"),
            onChanged: (value) {
              setState(() {
                _quantity = int.tryParse(value) ?? 1;
              });
              _atualizaTotalPreco();
            },
          ),
          SizedBox(height: 20),
          Text('Total: R\$ $_totalPrice'),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pedido realizado com sucesso!")));
            },
            child: Text('Enviar Pedido'),
          ),
        ],
      ),
    );
  }
}
