import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ardi/screens/accueil.dart';
import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/utils/auth.dart';

class ChatPage extends StatefulWidget {
  final String doctorId;
  final String name;
  final String specialization;
  final String image;

  const ChatPage({
    Key? key,
    required this.doctorId,
    required this.name,
    required this.specialization,
    required this.image,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late String _currentUserUid;
  late String _otherUserUid;
  late bool _isDoctor;
  bool _isLoading = true;
  bool _isRecording = false;
  late AnimationController _animationController;
  final Map<String, bool> _playingState = {};
  final Map<String, double> _playbackPositions = {};
  final Map<String, double> _playbackDurations = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _initializeSession();
    _audioPlayer.onPositionChanged.listen((position) {
      if (_playingState.values.any((playing) => playing)) {
        final playingMessageId = _playingState.entries.firstWhere((entry) => entry.value).key;
        setState(() {
          _playbackPositions[playingMessageId] = position.inSeconds.toDouble();
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (_playingState.values.any((playing) => playing)) {
        final playingMessageId = _playingState.entries.firstWhere((entry) => entry.value).key;
        setState(() {
          _playbackDurations[playingMessageId] = duration.inSeconds.toDouble();
        });
      }
    });
  }

  Future<void> _initializeSession() async {
    _currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    String? role = await AuthService().getUserRole();

    if (role == 'admin') {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        (Route<dynamic> route) => false,
      );
    } else if (role == 'patient') {
      _isDoctor = false;
      _otherUserUid = widget.doctorId;
    } else if (role == 'docta') {
      _isDoctor = true;
      _otherUserUid = widget.doctorId;
    } else {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const AccueilPage()),
        (Route<dynamic> route) => false,
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendTextMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final messageData = {
      'patientUid': _isDoctor ? _otherUserUid : _currentUserUid,
      'doctorUid': _isDoctor ? _currentUserUid : _otherUserUid,
      'message': messageText,
      'type': 'text',
      'sender': _isDoctor ? 'doctor' : 'patient',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('msg').add(messageData);
    _messageController.clear();
  }

  Future<void> _sendImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    String fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = _storage.ref().child('chat_files/$_currentUserUid/$fileName');
    await storageRef.putFile(file);
    String downloadUrl = await storageRef.getDownloadURL();

    final messageData = {
      'patientUid': _isDoctor ? _otherUserUid : _currentUserUid,
      'doctorUid': _isDoctor ? _currentUserUid : _otherUserUid,
      'message': downloadUrl,
      'type': 'image',
      'sender': _isDoctor ? 'doctor' : 'patient',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('msg').add(messageData);
  }

  Future<void> _sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    File file = File(result.files.single.path!);
    String fileName = result.files.single.name;
    Reference storageRef = _storage.ref().child('chat_files/$_currentUserUid/$fileName');
    await storageRef.putFile(file);
    String downloadUrl = await storageRef.getDownloadURL();

    final messageData = {
      'patientUid': _isDoctor ? _otherUserUid : _currentUserUid,
      'doctorUid': _isDoctor ? _currentUserUid : _otherUserUid,
      'message': downloadUrl,
      'type': 'file',
      'fileName': fileName,
      'sender': _isDoctor ? 'doctor' : 'patient',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('msg').add(messageData);
  }

  Future<void> _sendVoiceMessage() async {
    if (_isRecording) {
      String? path = await _recorder.stop();
      if (path != null) {
        File file = File(path);
        String fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        Reference storageRef = _storage.ref().child('chat_files/$_currentUserUid/$fileName');
        await storageRef.putFile(file);
        String downloadUrl = await storageRef.getDownloadURL();

        final messageData = {
          'patientUid': _isDoctor ? _otherUserUid : _currentUserUid,
          'doctorUid': _isDoctor ? _currentUserUid : _otherUserUid,
          'message': downloadUrl,
          'type': 'voice',
          'sender': _isDoctor ? 'doctor' : 'patient',
          'timestamp': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('msg').add(messageData);
      }
      _animationController.reverse();
      setState(() => _isRecording = false);
    } else {
      if (await _recorder.hasPermission()) {
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        _animationController.repeat(reverse: true);
        setState(() => _isRecording = true);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission microphone refusée')));
      }
    }
  }

  Future<void> _togglePlayPause(String messageId, String url) async {
    if (_playingState[messageId] == true) {
      await _audioPlayer.pause();
      setState(() => _playingState[messageId] = false);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _playingState.forEach((key, value) {
          if (key != messageId) _playingState[key] = false;
        });
        _playingState[messageId] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.image.startsWith('http') ? NetworkImage(widget.image) : AssetImage(widget.image) as ImageProvider,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(widget.specialization, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('msg')
                  .where('patientUid', isEqualTo: _isDoctor ? _otherUserUid : _currentUserUid)
                  .where('doctorUid', isEqualTo: _isDoctor ? _currentUserUid : _otherUserUid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text('Aucun message pour le moment.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final messageId = messages[index].id;
                    final isSentByCurrentUser = messageData['sender'] == (_isDoctor ? 'doctor' : 'patient');
                    final type = messageData['type'] ?? 'text';

                    _playingState.putIfAbsent(messageId, () => false);
                    _playbackPositions.putIfAbsent(messageId, () => 0.0);
                    _playbackDurations.putIfAbsent(messageId, () => 0.0);

                    Widget messageContent;
                    switch (type) {
                      case 'image':
                        messageContent = GestureDetector(
                          onTap: () => _showImageDialog(context, messageData['message']),
                          child: Image.network(
                            messageData['message'],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        );
                        break;
                      case 'file':
                        messageContent = GestureDetector(
                          onTap: () => _showFileDialog(context, messageData['message'], messageData['fileName']),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.insert_drive_file, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  messageData['fileName'] ?? 'Fichier',
                                  style: TextStyle(color: isSentByCurrentUser ? Colors.white : Colors.black, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                        break;
                      case 'voice':
                        messageContent = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _playingState[messageId]! ? Icons.pause : Icons.play_arrow,
                                color: Colors.teal,
                              ),
                              onPressed: () => _togglePlayPause(messageId, messageData['message']),
                            ),
                            Expanded(
                              child: Slider(
                                value: _playbackPositions[messageId]!.clamp(0.0, _playbackDurations[messageId]!),
                                min: 0.0,
                                max: _playbackDurations[messageId]! > 0 ? _playbackDurations[messageId]! : 1.0,
                                onChanged: (value) async {
                                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                                  setState(() => _playbackPositions[messageId] = value);
                                },
                                activeColor: Colors.teal,
                                inactiveColor: Colors.grey,
                              ),
                            ),
                            Text(
                              '${(_playbackPositions[messageId]! ~/ 60).toString().padLeft(2, '0')}:${(_playbackPositions[messageId]! % 60).toString().padLeft(2, '0')} / ${(_playbackDurations[messageId]! ~/ 60).toString().padLeft(2, '0')}:${(_playbackDurations[messageId]! % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(color: isSentByCurrentUser ? Colors.white : Colors.black, fontSize: 12),
                            ),
                          ],
                        );
                        break;
                      default: // 'text'
                        messageContent = Text(
                          messageData['message'],
                          style: TextStyle(color: isSentByCurrentUser ? Colors.white : Colors.black),
                        );
                    }

                    return Align(
                      alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSentByCurrentUser ? const Color.fromRGBO(204, 20, 205, 100) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: messageContent,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Color.fromRGBO(204, 20, 205, 100)),
                  onPressed: _sendImage,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color.fromRGBO(204, 20, 205, 100)),
                  onPressed: _sendFile,
                ),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: ColorTween(
                          begin: const Color.fromRGBO(204, 20, 205, 100),
                          end: Colors.red,
                        ).evaluate(_animationController) ?? const Color.fromRGBO(204, 20, 205, 100),
                      ),
                      onPressed: _sendVoiceMessage,
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Écrivez votre message...', border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromRGBO(204, 20, 205, 100)),
                  onPressed: _sendTextMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imageUrl),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileDialog(BuildContext context, String fileUrl, String? fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fileName ?? 'Fichier'),
        content: const Text('Le fichier a été envoyé. Voulez-vous le télécharger ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // Logique pour télécharger ou ouvrir le fichier (ex. url_launcher)
              Navigator.pop(context);
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }
}