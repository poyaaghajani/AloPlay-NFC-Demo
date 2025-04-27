// import 'dart:async';
// import 'dart:io';
//
// import 'package:android_intent_plus/android_intent.dart';
// import 'package:flutter/material.dart';
// import 'package:nfc_manager/nfc_manager.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Alo Play NFC Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       debugShowCheckedModeBanner: false,
//       home: const NFCWriterScreen(),
//     );
//   }
// }
//
// class NFCWriterScreen extends StatefulWidget {
//   const NFCWriterScreen({super.key});
//
//   @override
//   State<NFCWriterScreen> createState() => _NFCWriterScreenState();
// }
//
// class _NFCWriterScreenState extends State<NFCWriterScreen> {
//   String statusMessage = "Waiting...";
//   final userIdController = TextEditingController(text: "12345");
//   final amountController = TextEditingController(text: "50000");
//   final tokenController = TextEditingController(text: "abcd1234");
//   Timer? _sessionTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkNfcStatus();
//   }
//
//   @override
//   void dispose() {
//     userIdController.dispose();
//     amountController.dispose();
//     tokenController.dispose();
//     _sessionTimer?.cancel();
//     NfcManager.instance.stopSession();
//     super.dispose();
//   }
//
//   Future<void> _checkNfcStatus() async {
//     bool isAvailable = await NfcManager.instance.isAvailable();
//     if (!isAvailable && mounted) {
//       setState(() {
//         statusMessage =
//             "NFC is disabled. Please enable it in your device settings.";
//       });
//
//       showDialog(
//         context: context,
//         builder:
//             (context) => AlertDialog(
//               title: const Text("NFC Required"),
//               content: const Text(
//                 "NFC is disabled on your device. Would you like to go to settings to enable it?",
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     Navigator.pop(context);
//                     try {
//                       const intent = AndroidIntent(
//                         action: 'android.settings.NFC_SETTINGS',
//                       );
//                       await intent.launch();
//                     } catch (e) {
//                       print('Failed to launch NFC settings: $e');
//                       bool opened = await openAppSettings();
//                       if (!opened) {
//                         setState(() {
//                           statusMessage =
//                               "Failed to open settings. Please enable NFC manually.";
//                         });
//                       } else {
//                         setState(() {
//                           statusMessage =
//                               "Please navigate to NFC settings to enable it (e.g., Settings > Connected Devices > NFC).";
//                         });
//                       }
//                     }
//                   },
//                   child: const Text("Go to Settings"),
//                 ),
//               ],
//             ),
//       );
//     }
//   }
//
//   Future<void> writeToNFC(String userId, String amount, String token) async {
//     if (userId.isEmpty || amount.isEmpty || token.isEmpty) {
//       setState(() {
//         statusMessage = "Please fill in all fields.";
//       });
//       return;
//     }
//
//     String dataToSend = "ALO|USERID=$userId|AMOUNT=$amount|TOKEN=$token";
//     print('Writing to NFC: $dataToSend');
//
//     bool isAvailable = await NfcManager.instance.isAvailable();
//     print('NFC Available: $isAvailable');
//     if (!isAvailable) {
//       setState(() {
//         statusMessage =
//             "NFC is disabled. Please enable it in your device settings.";
//       });
//
//       showDialog(
//         context: context,
//         builder:
//             (context) => AlertDialog(
//               title: const Text("NFC Required"),
//               content: const Text(
//                 "NFC is disabled on your device. Would you like to go to settings to enable it?",
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     Navigator.pop(context);
//                     try {
//                       const intent = AndroidIntent(
//                         action: 'android.settings.NFC_SETTINGS',
//                       );
//                       await intent.launch();
//                     } catch (e) {
//                       print('Failed to launch NFC settings: $e');
//                       bool opened = await openAppSettings();
//                       if (!opened) {
//                         setState(() {
//                           statusMessage =
//                               "Failed to open settings. Please enable NFC manually.";
//                         });
//                       } else {
//                         setState(() {
//                           statusMessage =
//                               "Please navigate to NFC settings to enable it (e.g., Settings > Connected Devices > NFC).";
//                         });
//                       }
//                     }
//                   },
//                   child: const Text("Go to Settings"),
//                 ),
//               ],
//             ),
//       );
//       return;
//     }
//
//     setState(() {
//       statusMessage = "Please bring an NFC tag close to your device...";
//     });
//
//     _sessionTimer = Timer(const Duration(seconds: 30), () async {
//       await NfcManager.instance.stopSession();
//       if (mounted) {
//         setState(() {
//           statusMessage = "NFC session timed out. Please try again.";
//         });
//       }
//     });
//
//     NfcManager.instance.startSession(
//       onDiscovered: (NfcTag tag) async {
//         final ndef = Ndef.from(tag);
//         if (ndef != null) {
//           final message = await ndef.read();
//           for (var record in message.records) {
//             if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
//               // Assuming it's a text record
//               final text = String.fromCharCodes(
//                 record.payload,
//                 3,
//               ); // Skip the language code prefix
//               print('Read message: $text');
//               // Example: "ALO|USERID=12345|AMOUNT=50000|TOKEN=abcd1234"
//             }
//           }
//         }
//         await NfcManager.instance.stopSession();
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Alo Play - NFC Writer")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: userIdController,
//               decoration: const InputDecoration(labelText: "User ID"),
//             ),
//             TextField(
//               controller: amountController,
//               decoration: const InputDecoration(labelText: "Amount"),
//             ),
//             TextField(
//               controller: tokenController,
//               decoration: const InputDecoration(labelText: "Token"),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () {
//                 if (Platform.isAndroid) {
//                   writeToNFC(
//                     userIdController.text.trim(),
//                     amountController.text.trim(),
//                     tokenController.text.trim(),
//                   );
//                 } else {
//                   setState(() {
//                     statusMessage = "Only supported on Android";
//                   });
//                 }
//               },
//               child: const Text("Send via NFC"),
//             ),
//             const SizedBox(height: 24),
//             Text(statusMessage, style: const TextStyle(fontSize: 16)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:android_intent_plus/android_intent.dart';
// import 'package:flutter/material.dart';
// import 'package:nfc_manager/nfc_manager.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const NfcWriteScreen(),
//     );
//   }
// }

// class NfcWriteScreen extends StatefulWidget {
//   const NfcWriteScreen({super.key});

//   @override
//   _NfcWriteScreenState createState() => _NfcWriteScreenState();
// }

// class _NfcWriteScreenState extends State<NfcWriteScreen> {
//   String _status = 'Ready to emulate NFC card';
//   String _nfcAvailability = 'Checking...';
//   final String _dataToWrite = 'Hello, NFC Tag!';
//   bool _isSessionActive = false;

//   // Show dialog to prompt user to enable NFC
//   void _showNfcEnableDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('NFC Disabled'),
//             content: const Text(
//               'NFC is turned off. Please enable NFC in settings to continue.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   const intent = AndroidIntent(
//                     action: 'android.settings.NFC_SETTINGS',
//                   );
//                   await intent.launch();
//                 },
//                 child: const Text('Go to Settings'),
//               ),
//             ],
//           ),
//     );
//   }

//   // Show error dialog with retry option
//   void _showErrorDialog(String errorMessage) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('NFC Error'),
//             content: Text(errorMessage),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   // Reset status for retry
//                   setState(() {
//                     _status = 'Ready to emulate NFC card';
//                     _isSessionActive = false;
//                   });
//                 },
//                 child: const Text('Try Again'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//             ],
//           ),
//     );
//   }

//   Future<void> _startNfcEmulation() async {
//     // Stop any existing session to prevent conflicts
//     if (_isSessionActive) {
//       try {
//         await NfcManager.instance.stopSession();
//       } catch (_) {}
//       _isSessionActive = false;
//     }

//     try {
//       // Check NFC availability
//       bool isAvailable = await NfcManager.instance.isAvailable();
//       setState(() {
//         _nfcAvailability = isAvailable ? 'available' : 'disabled';
//       });

//       if (!isAvailable) {
//         _showNfcEnableDialog();
//         setState(() {
//           _status = 'NFC is disabled. Please enable it.';
//         });
//         return;
//       }

//       // Check if HCE is supported (basic check via NFC availability)
//       setState(() {
//         _status = 'Emulating NFC card... Hold near NFC reader';
//         _isSessionActive = true;
//       });

//       // Start NFC session for HCE
//       await NfcManager.instance.startSession(
//         onDiscovered: (NfcTag tag) async {
//           // HCE is handled by the Android system and MyHostApduService
//           setState(() {
//             _status = 'Data sent to NFC reader: $_dataToWrite';
//           });
//           // Stop session after successful interaction
//           await NfcManager.instance.stopSession();
//           setState(() {
//             _isSessionActive = false;
//           });
//         },
//         onError: (error) async {
//           String errorMessage;
//           if (error.toString().contains('NfcNotEnabled')) {
//             errorMessage =
//                 'NFC is disabled during the session. Please enable NFC and try again.';
//             _showNfcEnableDialog();
//           } else if (error.toString().contains('NfcNotSupported')) {
//             errorMessage = 'This device does not support NFC or HCE.';
//           } else {
//             errorMessage = 'NFC error: ${error.toString()}';
//           }
//           _showErrorDialog(errorMessage);
//           await NfcManager.instance.stopSession();
//           setState(() {
//             _isSessionActive = false;
//             _status = 'Error occurred. Ready to try again.';
//           });
//         },
//       );
//     } catch (e) {
//       String errorMessage;
//       if (e.toString().contains('SecurityException')) {
//         errorMessage =
//             'NFC permission denied. Please ensure NFC permissions are granted in app settings.';
//       } else if (e.toString().contains('HCE not supported')) {
//         errorMessage =
//             'Host Card Emulation (HCE) is not supported on this device.';
//       } else {
//         errorMessage = 'Unexpected error: ${e.toString()}';
//       }
//       _showErrorDialog(errorMessage);
//       setState(() {
//         _status = 'Error occurred. Ready to try again.';
//         _isSessionActive = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     if (_isSessionActive) {
//       NfcManager.instance.stopSession();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('NFC Card Emulation Example')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const Text(
//               'NFC Details',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text('NFC Availability: $_nfcAvailability'),
//             const SizedBox(height: 20),
//             const Text(
//               'Operation Status',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text('Status: $_status'),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isSessionActive ? null : _startNfcEmulation,
//               child: const Text('Start NFC Emulation'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
