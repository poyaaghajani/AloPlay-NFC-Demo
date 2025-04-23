import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart'; // Reintroduce android_intent_plus
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alo Play NFC Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const NFCWriterScreen(),
    );
  }
}

class NFCWriterScreen extends StatefulWidget {
  const NFCWriterScreen({super.key});

  @override
  State<NFCWriterScreen> createState() => _NFCWriterScreenState();
}

class _NFCWriterScreenState extends State<NFCWriterScreen> {
  String statusMessage = "Waiting...";
  final userIdController = TextEditingController(text: "12345");
  final amountController = TextEditingController(text: "50000");
  final tokenController = TextEditingController(text: "abcd1234");
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    // Check NFC status when the app starts
    _checkNfcStatus();
  }

  @override
  void dispose() {
    userIdController.dispose();
    amountController.dispose();
    tokenController.dispose();
    _sessionTimer?.cancel();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  // Check NFC status and prompt the user if it's disabled
  Future<void> _checkNfcStatus() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable && mounted) {
      setState(() {
        statusMessage =
            "NFC is disabled. Please enable it in your device settings.";
      });

      // Show a dialog to prompt the user to enable NFC
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("NFC Required"),
              content: const Text(
                "NFC is disabled on your device. Would you like to go to settings to enable it?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Try to launch the NFC settings page directly
                    try {
                      const intent = AndroidIntent(
                        action: 'android.settings.NFC_SETTINGS',
                      );
                      await intent.launch();
                    } catch (e) {
                      // Fallback to app settings if NFC settings intent fails
                      print('Failed to launch NFC settings: $e');
                      bool opened = await openAppSettings();
                      if (!opened) {
                        setState(() {
                          statusMessage =
                              "Failed to open settings. Please enable NFC manually.";
                        });
                      } else {
                        setState(() {
                          statusMessage =
                              "Please navigate to NFC settings to enable it (e.g., Settings > Connected Devices > NFC).";
                        });
                      }
                    }
                  },
                  child: const Text("Go to Settings"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> writeToNFC(String userId, String amount, String token) async {
    // Validate input
    if (userId.isEmpty || amount.isEmpty || token.isEmpty) {
      setState(() {
        statusMessage = "Please fill in all fields.";
      });
      return;
    }

    String dataToSend = "ALO|USERID=$userId|AMOUNT=$amount|TOKEN=$token";
    print('Writing to NFC: $dataToSend');

    // Check NFC availability again before starting the session
    bool isAvailable = await NfcManager.instance.isAvailable();
    print('NFC Available: $isAvailable');
    if (!isAvailable) {
      setState(() {
        statusMessage =
            "NFC is disabled. Please enable it in your device settings.";
      });

      // Prompt the user to enable NFC
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("NFC Required"),
              content: const Text(
                "NFC is disabled on your device. Would you like to go to settings to enable it?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      const intent = AndroidIntent(
                        action: 'android.settings.NFC_SETTINGS',
                      );
                      await intent.launch();
                    } catch (e) {
                      print('Failed to launch NFC settings: $e');
                      bool opened = await openAppSettings();
                      if (!opened) {
                        setState(() {
                          statusMessage =
                              "Failed to open settings. Please enable NFC manually.";
                        });
                      } else {
                        setState(() {
                          statusMessage =
                              "Please navigate to NFC settings to enable it (e.g., Settings > Connected Devices > NFC).";
                        });
                      }
                    }
                  },
                  child: const Text("Go to Settings"),
                ),
              ],
            ),
      );
      return;
    }

    // Update status to prompt user to scan a tag
    setState(() {
      statusMessage = "Please bring an NFC tag close to your device...";
    });

    // Start a timeout for the NFC session (30 seconds)
    _sessionTimer = Timer(const Duration(seconds: 30), () async {
      await NfcManager.instance.stopSession();
      if (mounted) {
        setState(() {
          statusMessage = "NFC session timed out. Please try again.";
        });
      }
    });

    // Start NFC session
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        print('Tag discovered: ${tag.data}');
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            print('Tag does not support NDEF');
            await NfcManager.instance.stopSession();
            if (mounted) {
              setState(() {
                statusMessage = "This NFC tag does not support NDEF.";
              });
            }
            return;
          }

          if (!ndef.isWritable) {
            print('Tag is not writable');
            await NfcManager.instance.stopSession();
            if (mounted) {
              setState(() {
                statusMessage = "This NFC tag is not writable.";
              });
            }
            return;
          }

          final record = NdefRecord.createText(dataToSend);
          final message = NdefMessage([record]);
          await ndef.write(message);

          print('Write successful');
          setState(() {
            statusMessage = "NFC message sent successfully!";
          });

          await NfcManager.instance.stopSession();
        } catch (e) {
          print('Error writing to tag: $e');
          await NfcManager.instance.stopSession();
          if (mounted) {
            setState(() {
              statusMessage = "Failed to write to NFC tag: $e";
            });
          }
        } finally {
          _sessionTimer?.cancel();
        }
      },
      onError: (error) async {
        print('NFC session error: $error');
        setState(() {
          statusMessage = "NFC session error: $error";
        });
        _sessionTimer?.cancel();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alo Play - NFC Writer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(labelText: "User ID"),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(labelText: "Token"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (Platform.isAndroid) {
                  writeToNFC(
                    userIdController.text.trim(),
                    amountController.text.trim(),
                    tokenController.text.trim(),
                  );
                } else {
                  setState(() {
                    statusMessage = "Only supported on Android";
                  });
                }
              },
              child: const Text("Send via NFC"),
            ),
            const SizedBox(height: 24),
            Text(statusMessage, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
