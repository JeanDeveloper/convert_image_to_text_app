import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  File? _image;

  String textConverted = "";

  bool isConverting = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      textConverted = "";
    });
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado al portapapeles'),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Convert Image to Text", 
          style: TextStyle(color: Colors.white)
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),

      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              child: InkWell(
                onTap: () => _showPicker(context),
                child: SizedBox(
                  width: 400,
                  height: 400,
                  child: Stack(
                    children: [
                      _image == null
                        ? Center(
                          child: SvgPicture.asset(
                            'assets/camera-icon.svg',
                            width: 100,
                            height: 100,
                            color: Colors.grey,
                          ),
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      if (_image != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            color: Theme.of(context).primaryColor,
                            icon: Icon(
                              Icons.delete, 
                              color: Theme.of(context).primaryColorDark, 
                              fill: 1.0, 
                              size: 40
                            ),
                            onPressed: (isConverting)
                              ? null
                              : _removeImage
                          ),
                        ),
                    ],
                  )
                ),
              ),
            ),

            SizedBox(height: size.height * .02),

            OutlinedButton(
              onPressed: (isConverting)
              ? null
              : () async {
                setState(() {
                  isConverting = true;
                });
                final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
                final InputImage inputImage = InputImage.fromFile(_image!);
                final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
                String text = recognizedText.text;
                setState((){
                  isConverting = false;
                  textConverted = "";
                  textConverted = text;
                  textRecognizer.close();
                });
              },
              child: (isConverting)
                ? const CircularProgressIndicator()
                : const Text("Convertir"), 
            ),

            SizedBox(height: size.height * .02),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              child:  SizedBox(
                width: 400,
                height: 400,
                child: SelectableText(
                  '''
                    $textConverted
                  ''',
                  contextMenuBuilder: ( _ , editableTextState) {
                    editableTextState.showToolbar();
                    return AdaptiveTextSelectionToolbar(
                      anchors: editableTextState.contextMenuAnchors,
                      children: [
                        TextSelectionToolbarTextButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Copiar'),
                          onPressed: () {
                            final selection = editableTextState.textEditingValue.selection;
                            final selectedText = editableTextState.textEditingValue.text.substring(selection.start, selection.end);
                            _copyToClipboard(context, selectedText);
                            editableTextState.hideToolbar();
                          },
                        ),
                        TextSelectionToolbarTextButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Seleccionar Todo'),
                          onPressed: () {
                            editableTextState.updateEditingValue(
                              TextEditingValue(
                                text: editableTextState.textEditingValue.text,
                                selection: TextSelection(
                                  baseOffset: 0,
                                  extentOffset: editableTextState.textEditingValue.text.length,
                                ),
                              ),
                            );
                            editableTextState.hideToolbar();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            )

          ],
        ),
      )
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

}