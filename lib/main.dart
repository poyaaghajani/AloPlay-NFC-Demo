import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const NfcScreen(),
    );
  }
}

class NfcScreen extends StatefulWidget {
  const NfcScreen({super.key});

  @override
  State<NfcScreen> createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> {
  String nfcData = 'Scan an NFC tag to read data';
  String statusMessage = 'Ready';
  bool isNfcAvailable = false;
  bool isProcessing = false;
  bool isReading = false;
  bool isWriting = false;

  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    textController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      isNfcAvailable = isAvailable;
      statusMessage = isAvailable ? 'NFC is available' : 'NFC is not available';
    });
  }

  void _writeNfcTag() {
    if (textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text to write')),
      );
      return;
    }

    setState(() {
      isProcessing = true;
      isWriting = true;
      statusMessage = 'Bring your device close to an NFC tag to write data...';
    });

    NfcManager.instance
        .startSession(
          onDiscovered: (NfcTag tag) async {
            Ndef? ndef = Ndef.from(tag);

            if (ndef == null) {
              _updateStatus('The tag doesn\'t support NDEF format', false);
              return;
            }

            if (!ndef.isWritable) {
              _updateStatus('The tag is not writable', false);
              return;
            }

            try {
              NdefMessage message = NdefMessage([
                NdefRecord.createText(textController.text),
              ]);

              await ndef.write(message);
              _updateStatus('✅ Data successfully written to tag!', false);
            } catch (e) {
              _updateStatus('❌ Write failed: $e', false);
            } finally {
              NfcManager.instance.stopSession();
              isWriting = false;
            }
          },
        )
        .catchError((e) {
          _updateStatus('Error starting NFC session: $e', false);
          isWriting = false;
        });
  }

  void _readNfcTag() {
    setState(() {
      isProcessing = true;
      isReading = true;
      statusMessage = 'Bring your device close to an NFC tag to read data...';
    });

    NfcManager.instance
        .startSession(
          onDiscovered: (NfcTag tag) async {
            Ndef? ndef = Ndef.from(tag);

            if (ndef == null) {
              _updateStatus('The tag doesn\'t support NDEF format', false);
              return;
            }

            try {
              NdefMessage? message = await ndef.read();
              if (message.records.isEmpty) {
                _updateStatus('Tag is empty or unreadable', false);
                return;
              }

              var firstRecord = message.records.first;
              if (firstRecord.typeNameFormat ==
                      NdefTypeNameFormat.nfcWellknown &&
                  firstRecord.type.isNotEmpty &&
                  firstRecord.type[0] == 0x54) {
                var payload = firstRecord.payload;
                String textData = String.fromCharCodes(
                  payload.sublist(payload[0] + 1),
                );
                setState(() {
                  nfcData = textData;
                  statusMessage = '✅ Successfully read data from tag';
                  isProcessing = false;
                });
              } else {
                _updateStatus('Tag contains non-text data', false);
              }
            } catch (e) {
              _updateStatus('❌ Read failed: $e', false);
            } finally {
              NfcManager.instance.stopSession();
              isReading = false;
            }
          },
        )
        .catchError((e) {
          _updateStatus('Error starting NFC session: $e', false);
          isReading = false;
        });
  }

  void _updateStatus(String message, bool processing) {
    setState(() {
      statusMessage = message;
      isProcessing = processing;
    });
  }

  void _cancelOperation() {
    NfcManager.instance.stopSession();
    setState(() {
      isProcessing = false;
      isReading = false;
      isWriting = false;
      statusMessage = 'Operation cancelled';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Tag Reader/Writer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    if (isProcessing)
                      Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            isProcessing
                                ? Colors.blue
                                : statusMessage.contains('❌')
                                ? Colors.red
                                : statusMessage.contains('✅')
                                ? Colors.green
                                : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isProcessing)
                      TextButton(
                        onPressed: _cancelOperation,
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ),
            ),

            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Write to NFC Tag',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        labelText: 'Enter data to write',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isProcessing,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed:
                          isProcessing || !isNfcAvailable ? null : _writeNfcTag,
                      icon: const Icon(Icons.send),
                      label: const Text('Write to Tag'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Read from NFC Tag',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed:
                          isProcessing || !isNfcAvailable ? null : _readNfcTag,
                      icon: const Icon(Icons.nfc),
                      label: const Text('Read from Tag'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tag Content:',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            nfcData,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!isNfcAvailable)
              Card(
                color: Colors.red.shade100,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'NFC is not available on this device or is turned off in settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
