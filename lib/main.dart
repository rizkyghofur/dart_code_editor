import 'dart:convert';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Beranda(),
  ));
}

class Beranda extends StatefulWidget {
  const Beranda({Key key}) : super(key: key);

  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  CodeController _codeController;
  Map<String, TextStyle> theme = monokaiSublimeTheme;
  String output = "";
  int sisaCredit = 0;
  bool selesaiCompile = true;

  @override
  void initState() {
    super.initState();
    cekCreditSpent();
    _codeController = CodeController(
      language: dart,
      theme: theme,
    );
  }

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  void eksekusiCompile() async {
    setState(() {
      selesaiCompile = false;
    });

    var sourceCode = _codeController.text;
    sourceCode = sourceCode.toString().replaceAll("'", '"');
    if (sourceCode.contains('·')) {
      sourceCode = sourceCode.toString().replaceAll("·", " ");
    }
    print(sourceCode);
    var url = Uri.parse('https://api.jdoodle.com/v1/execute');
    Map<String, String> header = {
      "Content-Type": "application/json",
    };
    var body = jsonEncode({
      "clientId": "c6b07926f41c10e991de94b85bb87aef",
      "clientSecret":
          "4e641110f67045313bd9728bcd2e3bf4b08d8ec0216e8e8e26c2b3c16ea60b1b",
      "script": sourceCode,
      "language": "dart",
      "versionIndex": "0",
    });
    try {
      var response = await http.post(
        url,
        headers: header,
        body: body,
      );
      var code = response.statusCode;
      setState(() {
        if (code == 200) {
          cekCreditSpent();
          var body = response.body;
          print(body);
          var res = json.decode(body);
          output = res['output'];
          selesaiCompile = true;
        } else {
          var body = response.body;
          output = "error";
          selesaiCompile = true;
          print(body);
        }
      });
    } catch (e) {
      setState(() {
        output = "error";
        selesaiCompile = true;
      });
      print(e);
    }
  }

  void cekCreditSpent() async {
    var url = Uri.parse('https://api.jdoodle.com/v1/credit-spent');
    Map<String, String> header = {
      "Content-Type": "application/json",
    };
    var body = jsonEncode({
      "clientId": "c6b07926f41c10e991de94b85bb87aef",
      "clientSecret":
          "4e641110f67045313bd9728bcd2e3bf4b08d8ec0216e8e8e26c2b3c16ea60b1b",
    });
    try {
      var response = await http.post(
        url,
        headers: header,
        body: body,
      );
      var code = response.statusCode;
      setState(() {
        if (code == 200) {
          var body = response.body;
          print(body);
          var res = json.decode(body);
          sisaCredit = res['used'];
        } else {
          print(body);
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dart Code Editor"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: CodeField(
              minLines: 25,
              wrap: true,
              controller: _codeController,
              textStyle: TextStyle(fontFamily: 'SourceCode', fontSize: 20),
            ),
          ),
          !selesaiCompile
              ? Flexible(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Flexible(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Output: ', style: TextStyle(fontSize: 16)),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          output,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => sisaCredit == 200
            ? ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    "Anda telah mencapai batas limit penggunaan compiler, coba lagi besok...")))
            : eksekusiCompile(),
        child: Icon(
          Icons.play_arrow_sharp,
        ),
      ),
    );
  }
}
