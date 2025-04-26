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

import 'dart:async';
import 'dart:io' show Platform, sleep;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:logging/logging.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:ndef/utilities.dart';
import 'package:test_new/raw_record_setting.dart';
import 'package:test_new/text_record_setting.dart';
import 'package:test_new/uri_record_setting.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(MaterialApp(theme: ThemeData(useMaterial3: true), home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  String _platformVersion = '';
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String? _result, _writeResult, _mifareResult;
  late TabController _tabController;
  List<ndef.NDEFRecord>? _records;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _platformVersion =
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } else {
      _platformVersion = 'Web';
    }
    initPlatformState();
    _tabController = TabController(length: 2, vsync: this);
    _records = [];
    FlutterNfcKit.tagStream.listen((tag) {
      setState(() {
        _tag = tag;
        print(_tag);
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    NFCAvailability availability;
    try {
      availability = await FlutterNfcKit.nfcAvailability;
    } on PlatformException {
      availability = NFCAvailability.not_supported;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
      _availability = availability;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('NFC Flutter Kit Example App'),
          bottom: TabBar(
            tabs: <Widget>[Tab(text: 'Read'), Tab(text: 'Write')],
            controller: _tabController,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            Scrollbar(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      Text(
                        'Running on: $_platformVersion\nNFC: $_availability',
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            NFCTag tag = await FlutterNfcKit.poll();
                            setState(() {
                              _tag = tag;
                            });
                            await FlutterNfcKit.setIosAlertMessage(
                              "Working on it...",
                            );
                            _mifareResult = null;
                            if (tag.standard == "ISO 14443-4 (Type B)") {
                              String result1 = await FlutterNfcKit.transceive(
                                "00B0950000",
                              );
                              String result2 = await FlutterNfcKit.transceive(
                                "00A4040009A00000000386980701",
                              );
                              setState(() {
                                _result = '1: $result1\n2: $result2\n';
                              });
                            } else if (tag.type == NFCTagType.iso18092) {
                              String result1 = await FlutterNfcKit.transceive(
                                "060080080100",
                              );
                              setState(() {
                                _result = '1: $result1\n';
                              });
                            } else if (tag.ndefAvailable ?? false) {
                              var ndefRecords =
                                  await FlutterNfcKit.readNDEFRecords();
                              var ndefString = '';
                              for (int i = 0; i < ndefRecords.length; i++) {
                                ndefString += '${i + 1}: ${ndefRecords[i]}\n';
                              }
                              setState(() {
                                _result = ndefString;
                              });
                            } else if (tag.type == NFCTagType.webusb) {
                              var r = await FlutterNfcKit.transceive(
                                "00A4040006D27600012401",
                              );
                              print(r);
                            }
                          } catch (e) {
                            setState(() {
                              _result = 'error: $e';
                            });
                          }

                          // Pretend that we are working
                          if (!kIsWeb) sleep(Duration(seconds: 1));
                          await FlutterNfcKit.finish(
                            iosAlertMessage: "Finished!",
                          );
                        },
                        child: Text('Start polling'),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child:
                            _tag != null
                                ? Text(
                                  'ID: ${_tag!.id}\nStandard: ${_tag!.standard}\nType: ${_tag!.type}\nATQA: ${_tag!.atqa}\nSAK: ${_tag!.sak}\nHistorical Bytes: ${_tag!.historicalBytes}\nProtocol Info: ${_tag!.protocolInfo}\nApplication Data: ${_tag!.applicationData}\nHigher Layer Response: ${_tag!.hiLayerResponse}\nManufacturer: ${_tag!.manufacturer}\nSystem Code: ${_tag!.systemCode}\nDSF ID: ${_tag!.dsfId}\nNDEF Available: ${_tag!.ndefAvailable}\nNDEF Type: ${_tag!.ndefType}\nNDEF Writable: ${_tag!.ndefWritable}\nNDEF Can Make Read Only: ${_tag!.ndefCanMakeReadOnly}\nNDEF Capacity: ${_tag!.ndefCapacity}\nMifare Info:${_tag!.mifareInfo} Transceive Result:\n$_result\n\nBlock Message:\n$_mifareResult',
                                )
                                : const Text('No tag polled yet.'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          if (_records!.isNotEmpty) {
                            try {
                              NFCTag tag = await FlutterNfcKit.poll();
                              setState(() {
                                _tag = tag;
                              });
                              if (tag.type == NFCTagType.mifare_ultralight ||
                                  tag.type == NFCTagType.mifare_classic ||
                                  tag.type == NFCTagType.iso15693) {
                                await FlutterNfcKit.writeNDEFRecords(_records!);
                                setState(() {
                                  _writeResult = 'OK';
                                });
                              } else {
                                setState(() {
                                  _writeResult =
                                      'error: NDEF not supported: ${tag.type}';
                                });
                              }
                            } catch (e, stacktrace) {
                              setState(() {
                                _writeResult = 'error: $e';
                              });
                              print(stacktrace);
                            } finally {
                              await FlutterNfcKit.finish();
                            }
                          } else {
                            setState(() {
                              _writeResult = 'error: No record';
                            });
                          }
                        },
                        child: Text("Start writing"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleDialog(
                                title: Text("Record Type"),
                                children: <Widget>[
                                  SimpleDialogOption(
                                    child: Text("Text Record"),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return NDEFTextRecordSetting();
                                          },
                                        ),
                                      );
                                      if (result != null) {
                                        if (result is ndef.TextRecord) {
                                          setState(() {
                                            _records!.add(result);
                                          });
                                        }
                                      }
                                    },
                                  ),
                                  SimpleDialogOption(
                                    child: Text("Uri Record"),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return NDEFUriRecordSetting();
                                          },
                                        ),
                                      );
                                      if (result != null) {
                                        if (result is ndef.UriRecord) {
                                          setState(() {
                                            _records!.add(result);
                                          });
                                        }
                                      }
                                    },
                                  ),
                                  SimpleDialogOption(
                                    child: Text("Raw Record"),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return NDEFRecordSetting();
                                          },
                                        ),
                                      );
                                      if (result != null) {
                                        if (result is ndef.NDEFRecord) {
                                          setState(() {
                                            _records!.add(result);
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text("Add record"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Result: $_writeResult'),
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      shrinkWrap: true,
                      children: List<Widget>.generate(
                        _records!.length,
                        (index) => GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              'id:${_records![index].idString}\ntnf:${_records![index].tnf}\ntype:${_records![index].type?.toHexString()}\npayload:${_records![index].payload?.toHexString()}\n',
                            ),
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return NDEFRecordSetting(
                                    record: _records![index],
                                  );
                                },
                              ),
                            );
                            if (result != null) {
                              if (result is ndef.NDEFRecord) {
                                setState(() {
                                  _records![index] = result;
                                });
                              } else if (result is String &&
                                  result == "Delete") {
                                _records!.removeAt(index);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
