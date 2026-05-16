// lib/widgets/project_media_carousel.dart
// Reusable carousel for project images + videos.
// Used in donate sheet / project detail view.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../services/donation_service.dart';

class ProjectMediaCarousel extends StatefulWidget {
  final List<ProjectMedia> media;
  final double height;
  final BorderRadius? borderRadius;

  const ProjectMediaCarousel({
    super.key,
    required this.media,
    this.height = 220,
    this.borderRadius,
  });

  @override
  State<ProjectMediaCarousel> createState() => _ProjectMediaCarouselState();
}

class _ProjectMediaCarouselState extends State<ProjectMediaCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _prefetchedInitial = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefetchedInitial) {
      _prefetchedInitial = true;
      // Warm the image cache for the visible slide + the next two so the
      // first swipe is instant. Fire-and-forget; precacheImage handles
      // network internally via CachedNetworkImageProvider.
      _prefetchAround(0);
    }
  }

  void _prefetchAround(int center) {
    for (final delta in const [0, 1, 2, -1]) {
      final idx = center + delta;
      if (idx < 0 || idx >= widget.media.length) continue;
      final m = widget.media[idx];
      if (m.isVideo) continue; // videos init themselves on demand
      precacheImage(
        CachedNetworkImageProvider(m.url),
        context,
        onError: (_, __) {},
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return _emptyPlaceholder();
    }
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.media.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
                // Stay one ahead of the user's swipes so the next slide
                // is always already decoded.
                _prefetchAround(i);
              },
              itemBuilder: (_, i) {
                final m = widget.media[i];
                return m.isVideo
                    ? _VideoSlide(url: m.url)
                    : _ImageSlide(url: m.url);
              },
            ),

            // Caption overlay (bottom)
            if (widget.media[_currentIndex].caption != null &&
                widget.media[_currentIndex].caption!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Text(
                    widget.media[_currentIndex].caption!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Page indicator dots
            if (widget.media.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.media.length, (i) {
                    final selected = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

            // Counter chip (top right)
            if (widget.media.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.media.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Left arrow
            if (widget.media.length > 1 && _currentIndex > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap:
                        () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),

            // Right arrow
            if (widget.media.length > 1 &&
                _currentIndex < widget.media.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap:
                        () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPlaceholder() {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        color: const Color(0xFFF1F5F4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No media yet',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image slide ─────────────────────────────────────────────────────────
class _ImageSlide extends StatelessWidget {
  final String url;
  const _ImageSlide({required this.url});

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (ctx) => Scaffold(
              backgroundColor: Colors.black,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              body: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white70,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cream underlay (matches Y4 theme) instead of pure black so an
          // uncached frame never reads as a "black screen" — it looks like
          // a soft empty card while the image fades in.
          Container(
            color: const Color(0xFFF5EBC8),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, __) => Container(
                color: const Color(0xFFF5EBC8),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Color(0x55000000),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFFF5EBC8),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0x88000000),
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fullscreen_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video slide ─────────────────────────────────────────────────────────
class _VideoSlide extends StatefulWidget {
  final String url;
  const _VideoSlide({required this.url});

  @override
  State<_VideoSlide> createState() => _VideoSlideState();
}

class _VideoSlideState extends State<_VideoSlide> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF2BAE7C),
          handleColor: const Color(0xFF2BAE7C),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        placeholder: Container(color: Colors.black),
      );
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'Could not load video';
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_error != null || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white54,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Video error',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      color: Colors.black,
      child: Chewie(controller: _chewieController!),
    );
  }
}
