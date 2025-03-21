import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class PlantIdentification {
  final String scientificName;
  final String commonNames;
  final List<Map<String, dynamic>> results;

  PlantIdentification({
    required this.scientificName,
    required this.commonNames,
    required this.results,
  });

  factory PlantIdentification.fromJson(Map<String, dynamic> json) {
    return PlantIdentification(
      scientificName: json['best_match_scientific_name'] ?? 'Unknown',
      commonNames: json['best_match_common_names'] ?? 'Unknown',
      results: List<Map<String, dynamic>>.from(json['results']['results'] ?? []),
    );
  }
}

class IdentifyPlantScreen extends StatefulWidget {
  const IdentifyPlantScreen({super.key});

  @override
  State<IdentifyPlantScreen> createState() => _IdentifyPlantScreenState();
}

class _IdentifyPlantScreenState extends State<IdentifyPlantScreen> {
  dynamic _image;
  Map<String, dynamic>? _identificationResult;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
        _identificationResult = null;
      });

      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );

        if (result != null) {
          setState(() {
            _image = result.files.first.bytes;
          });
          await _sendImageToBackend(result.files.first.bytes!);
        }
      } else {
        final pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          final imageBytes = await File(pickedFile.path).readAsBytes();
          setState(() {
            _image = File(pickedFile.path);
          });
          await _sendImageToBackend(imageBytes);
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendImageToBackend(List<int> imageBytes) async {
    try {
      final uri = Uri.parse('http://127.0.0.1:8000/api/identify/');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'plant_image.jpg',
        ),
      );

      print('Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _identificationResult = data;
        });
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _showError('Error identifying plant: $e');
    }
  }

  void _showError(String message) {
    print('Error: $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Identifier'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.memory(_image, fit: BoxFit.cover)
                      : Image.file(_image, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_identificationResult != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scientific Name: ${_identificationResult!['best_match_scientific_name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Common Names: ${_identificationResult!['best_match_common_names']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Other Possible Matches:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_identificationResult!['results']['results'] as List)
                          .take(3)
                          .map((result) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  '${result['scientific_name']} (${(result['score'] * 100).toStringAsFixed(1)}%)',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}