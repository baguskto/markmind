import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:share_handler/share_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late StreamSubscription _intentDataStreamSubscription;
  final _urlPattern = RegExp(
      r'https?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+');

  Map<String, PreviewData> _previewDataMap = {};
  List<String> _urls = [];
  SharedMedia? _media;
  String instructionText = "Start bookmarking now! 🚀\n"
      "1. Go to the content you want to save.\n"
      "2. Tap on the 'Share' option.\n"
      "3. Look for 'MarkMind' in the share menu and select it.\n"
      "Your bookmark will then appear here!";

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> _deleteUrl(int index) async {
    setState(() {
      _urls.removeAt(index);
    });
    await _saveUrls();
  }

  Future<void> _saveUrls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedUrls', _urls);
  }

  Future<void> _loadUrls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedUrls = prefs.getStringList('savedUrls');
    if (savedUrls != null) {
      setState(() {
        _urls = savedUrls;
      });
    }
  }

  Future<void> _initPlatformState() async {
    await _loadUrls();

    final handler = ShareHandlerPlatform.instance;
    _media = await handler.getInitialSharedMedia();

    handler.sharedMediaStream.listen((SharedMedia media) {
      if (!mounted) return;
      final sharedText = _urlPattern.stringMatch(media.content!);
      if (sharedText != null && !_urls.contains(sharedText)) {
        setState(() {
          _urls.insert(0, sharedText);
        });
        _saveUrls();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    if (_urls.isEmpty) return _buildEmptyState();
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return UpgradeAlert(
      upgrader: Upgrader(
          canDismissDialog: false, dialogStyle: UpgradeDialogStyle.cupertino),
      child: Scaffold(
        appBar: AppBar(title: Text('MarkMind')),
        backgroundColor: Colors.white,
        body: ListView.builder(
          itemCount: _urls.length,
          itemBuilder: (context, index) => _buildLinkPreview(index),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return UpgradeAlert(
      upgrader: Upgrader(
          canDismissDialog: false, dialogStyle: UpgradeDialogStyle.cupertino),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('MarkMind')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_off, size: 50, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                instructionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkPreview(int index) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: ValueKey(_urls[index]),
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Color(0xfff7f7f8),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: LinkPreview(
                enableAnimation: true,
                hideImage: false,
                onPreviewDataFetched: (data) => _onDataFetched(index, data),
                openOnPreviewImageTap: true,
                openOnPreviewTitleTap: true,
                onLinkPressed: (selectedUrl) => _launchUrl(selectedUrl),
                previewData: _previewDataMap[_urls[index]],
                text: _urls[index],
                width: MediaQuery.of(context).size.width,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _deleteUrl(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDataFetched(int index, PreviewData data) {
    setState(() {
      _previewDataMap[_urls[index]] = data;
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uriLink = Uri.parse(url);
      await launchUrl(uriLink, mode: LaunchMode.externalApplication);
    } catch (e) {
      throw Exception('Could not launch $url');
    }
  }
}
