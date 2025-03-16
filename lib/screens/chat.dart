import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http; // Ajout pour télécharger les fichiers
import 'package:path_provider/path_provider.dart'; // Ajout pour le stockage temporaire
import 'package:share_plus/share_plus.dart'; // Ajout pour partager les fichiers
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

class _ChatPageState extends State<ChatPage> {
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
  bool _isPaused = false;
  String? _currentAudioPath;
  Duration _recordingDuration = Duration.zero;
  File? _selectedImage;
  File? _selectedFile;

  final Map<String, bool> _playingState = {};
  final Map<String, double> _playbackPositions = {};
  final Map<String, double> _playbackDurations = {};

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _audioPlayer.onPositionChanged.listen((position) {
      if (_playingState.values.any((playing) => playing)) {
        final playingMessageId =
            _playingState.entries.firstWhere((entry) => entry.value).key;
        setState(() {
          _playbackPositions[playingMessageId] = position.inSeconds.toDouble();
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (_playingState.values.any((playing) => playing)) {
        final playingMessageId =
            _playingState.entries.firstWhere((entry) => entry.value).key;
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
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _sendSelectedImage() async {
    if (_selectedImage == null) return;

    String fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef =
        _storage.ref().child('chat_files/$_currentUserUid/$fileName');
    await storageRef.putFile(_selectedImage!);
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
    setState(() => _selectedImage = null);
  }

  Future<void> _sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    setState(() {
      _selectedFile = File(result.files.single.path!);
    });
  }

  Future<void> _sendSelectedFile() async {
    if (_selectedFile == null) return;

    String fileName = _selectedFile!.path.split('/').last;
    Reference storageRef =
        _storage.ref().child('chat_files/$_currentUserUid/$fileName');
    await storageRef.putFile(_selectedFile!);
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
    setState(() => _selectedFile = null);
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      _currentAudioPath =
          '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _currentAudioPath!,
      );
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = Duration.zero;
      });
      _updateRecordingDuration();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission microphone refusée')),
      );
    }
  }

  Future<void> _pauseRecording() async {
    if (_isRecording && !_isPaused) {
      await _recorder.pause();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _resumeRecording() async {
    if (_isRecording && _isPaused) {
      await _recorder.resume();
      setState(() => _isPaused = false);
      _updateRecordingDuration();
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (_isRecording) {
      String? path = await _recorder.stop();
      if (path != null) {
        File file = File(path);
        String fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        Reference storageRef =
            _storage.ref().child('chat_files/$_currentUserUid/$fileName');
        await storageRef.putFile(file);
        String downloadUrl = await storageRef.getDownloadURL();

        final messageData = {
          'patientUid': _isDoctor ? _otherUserUid : _currentUserUid,
          'doctorUid': _isDoctor ? _currentUserUid : _otherUserUid,
          'message': downloadUrl,
          'type': 'voice',
          'sender': _isDoctor ? 'doctor' : 'patient',
          'duration': _recordingDuration.inSeconds,
          'timestamp': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('msg').add(messageData);
      }
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _currentAudioPath = null;
        _recordingDuration = Duration.zero;
      });
    }
  }

  Future<void> _cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _currentAudioPath = null;
        _recordingDuration = Duration.zero;
      });
    }
  }

  void _updateRecordingDuration() {
    if (_isRecording && !_isPaused) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isRecording && !_isPaused) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
          _updateRecordingDuration();
        }
      });
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(204, 20, 205, 100), Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: widget.image.startsWith('http')
                  ? NetworkImage(widget.image)
                  : AssetImage(widget.image) as ImageProvider,
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.specialization,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade50.withOpacity(0.5),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('msg')
                      .where('patientUid',
                          isEqualTo:
                              _isDoctor ? _otherUserUid : _currentUserUid)
                      .where('doctorUid',
                          isEqualTo:
                              _isDoctor ? _currentUserUid : _otherUserUid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                              Color.fromRGBO(204, 20, 205, 100)),
                        ),
                      );
                    }
                    final messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun message pour le moment.',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageData =
                            messages[index].data() as Map<String, dynamic>;
                        final messageId = messages[index].id;
                        final isSentByCurrentUser = messageData['sender'] ==
                            (_isDoctor ? 'doctor' : 'patient');
                        final type = messageData['type'] ?? 'text';
                        final timestamp =
                            (messageData['timestamp'] as Timestamp?)?.toDate();
                        final duration = messageData['duration'] as int? ?? 0;

                        _playingState.putIfAbsent(messageId, () => false);
                        _playbackPositions.putIfAbsent(messageId, () => 0.0);
                        _playbackDurations.putIfAbsent(
                            messageId, () => duration.toDouble());

                        Widget messageContent;
                        switch (type) {
                          case 'image':
                            messageContent = GestureDetector(
                              onTap: () => _showImageDialog(
                                  context, messageData['message']),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  messageData['message'],
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                            break;
                          case 'file':
                            messageContent = GestureDetector(
                              onTap: () => _showFileDialog(
                                  context,
                                  messageData['message'],
                                  messageData['fileName']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file,
                                      color: Color.fromRGBO(204, 20, 205, 100),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        messageData['fileName'] ?? 'Fichier',
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            break;
                          case 'voice':
                            messageContent = Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _playingState[messageId]!
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: const Color.fromRGBO(
                                          204, 20, 205, 100),
                                    ),
                                    onPressed: () => _togglePlayPause(
                                        messageId, messageData['message']),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _playbackPositions[messageId]!
                                          .clamp(0.0,
                                              _playbackDurations[messageId]!),
                                      min: 0.0,
                                      max: _playbackDurations[messageId]!,
                                      onChanged: (value) async {
                                        await _audioPlayer.seek(
                                            Duration(seconds: value.toInt()));
                                        setState(() =>
                                            _playbackPositions[messageId] =
                                                value);
                                      },
                                      activeColor: const Color.fromRGBO(
                                          204, 20, 205, 100),
                                      inactiveColor: Colors.grey.shade400,
                                    ),
                                  ),
                                  Text(
                                    '${(_playbackDurations[messageId]! ~/ 60).toString().padLeft(2, '0')}:${(_playbackDurations[messageId]! % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        color: Colors.black87, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                            break;
                          default: // 'text'
                            messageContent = Text(
                              messageData['message'],
                              style: TextStyle(
                                color: isSentByCurrentUser
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16,
                              ),
                            );
                        }

                        return Align(
                          alignment: isSentByCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSentByCurrentUser
                                  ? const Color.fromRGBO(204, 20, 205, 1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7),
                            child: Column(
                              crossAxisAlignment: isSentByCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                messageContent,
                                if (timestamp != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSentByCurrentUser
                                            ? Colors.white70
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
            ),
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _sendSelectedImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(204, 20, 205, 100),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Envoyer'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            if (_selectedFile != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file,
                              color: Color.fromRGBO(204, 20, 205, 100)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFile!.path.split('/').last,
                              style: const TextStyle(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _sendSelectedFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(204, 20, 205, 100),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Envoyer'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedFile = null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_isRecording)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Durée : ${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    IconButton(
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause,
                          color: const Color.fromRGBO(204, 20, 205, 100)),
                      onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                      tooltip: _isPaused ? 'Reprendre' : 'Pause',
                    ),
                    IconButton(
                      icon: const Icon(Icons.send,
                          color: Color.fromRGBO(204, 20, 205, 100)),
                      onPressed: _stopAndSendRecording,
                      tooltip: 'Envoyer',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _cancelRecording,
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add,
                        color: Color.fromRGBO(204, 20, 205, 100)),
                    onSelected: (value) {
                      switch (value) {
                        case 'photo':
                          _sendImage();
                          break;
                        case 'file':
                          _sendFile();
                          break;
                        case 'audio':
                          _startRecording();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'photo',
                        child: Row(
                          children: [
                            Icon(Icons.image,
                                color: Color.fromRGBO(204, 20, 205, 100)),
                            SizedBox(width: 8),
                            Text('Photo'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'file',
                        child: Row(
                          children: [
                            Icon(Icons.attach_file,
                                color: Color.fromRGBO(204, 20, 205, 100)),
                            SizedBox(width: 8),
                            Text('Fichier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'audio',
                        child: Row(
                          children: [
                            Icon(Icons.mic,
                                color: Color.fromRGBO(204, 20, 205, 100)),
                            SizedBox(width: 8),
                            Text('Audio'),
                          ],
                        ),
                      ),
                    ],
                    offset: const Offset(0, -120),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrivez votre message...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send,
                        color: Color.fromRGBO(204, 20, 205, 100)),
                    onPressed: _sendTextMessage,
                    tooltip: 'Envoyer le message',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Fermer',
                  style: TextStyle(color: Color.fromRGBO(204, 20, 205, 100)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileDialog(
      BuildContext context, String fileUrl, String? fileName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          fileName ?? 'Fichier',
          style: const TextStyle(color: Color.fromRGBO(204, 20, 205, 100)),
        ),
        content: const Text('Voulez-vous télécharger ce fichier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Télécharger le fichier depuis l'URL
                final response = await http.get(Uri.parse(fileUrl));
                if (response.statusCode != 200) {
                  throw Exception('Erreur lors du téléchargement du fichier');
                }

                // Sauvegarder temporairement le fichier
                final directory = await getTemporaryDirectory();
                final filePath =
                    '${directory.path}/${fileName ?? 'downloaded_file_${DateTime.now().millisecondsSinceEpoch}'}';
                final file = File(filePath);
                await file.writeAsBytes(response.bodyBytes);

                // Partager le fichier avec share_plus (simule un téléchargement en l'ouvrant)
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text:
                      'Voici le fichier téléchargé : ${fileName ?? 'Fichier'}',
                );

                // Nettoyer le fichier temporaire après partage
                await file.delete();

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors du téléchargement : $e')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Télécharger',
              style: TextStyle(color: Color.fromRGBO(204, 20, 205, 100)),
            ),
          ),
        ],
      ),
    );
  }
}
