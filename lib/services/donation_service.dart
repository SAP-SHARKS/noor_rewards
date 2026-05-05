// lib/services/donation_service.dart
// Handles donations to community projects via Supabase

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'notification_center.dart';

/// Single media item attached to a community project (image or video).
class ProjectMedia {
  final String id;
  final String projectId;
  final String mediaType; // 'image' or 'video'
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final int sortOrder;

  const ProjectMedia({
    required this.id,
    required this.projectId,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.sortOrder = 0,
  });

  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';

  factory ProjectMedia.fromJson(Map<String, dynamic> j) => ProjectMedia(
    id: j['id'] as String,
    projectId: j['project_id'] as String,
    mediaType: j['media_type'] as String? ?? 'image',
    url: j['url'] as String? ?? '',
    thumbnailUrl: j['thumbnail_url'] as String?,
    caption: j['caption'] as String?,
    sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
  );
}

class DonationService {
  DonationService._();
  static final DonationService instance = DonationService._();

  final _sb = Supabase.instance.client;
  static const _mediaBucket = 'project-media';

  /// Donates [amount] to a community [projectId].
  /// Returns null if successful, otherwise an error string.
  Future<String?> donate(String projectId, int amount) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return "You must be logged in to donate.";

    try {
      final success = await _sb.rpc(
        'donate_to_project',
        params: {
          'p_user_id': uid,
          'p_project_id': projectId,
          'p_amount': amount,
        },
      );

      if (success == true) {
        // ── In-app notification: donation succeeded. Tap goes to Akhirah
        // tab where the user's giving impact is summarised.
        NotificationCenter.instance.add(
          kind: NoorNotifKind.donation,
          title: 'Donation received 💝',
          body: 'You donated $amount Noor Points · jazak Allah khair.',
          route: '/akhirah',
          data: {'project_id': projectId, 'amount': amount},
        );
        return null; // Null means success
      } else {
        return "Donation could not be processed at this time.";
      }
    } catch (e) {
      if (e is PostgrestException) {
        return e.message;
      }
      return "An unexpected network error occurred.";
    }
  }

  /// Calculates the total lifetime donations made by the current user.
  Future<int> getUserTotalDonations() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 0;

    try {
      final response = await _sb
          .from('user_donations')
          .select('points_donated')
          .eq('user_id', uid);

      int total = 0;
      for (final row in response) {
        total += (row['points_donated'] as num?)?.toInt() ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Returns a list of projects the current user has donated to,
  /// with their personal donation total and project details.
  Future<List<Map<String, dynamic>>> getUserProjectDonations() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final List<dynamic> data = await _sb.rpc(
        'get_user_project_donations',
        params: {'p_user_id': uid},
      );
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── Project Media (carousel) ────────────────────────────────────────────

  /// Loads all media items for a single project, ordered by sort_order.
  Future<List<ProjectMedia>> getProjectMedia(String projectId) async {
    try {
      final res = await _sb
          .from('community_project_media')
          .select()
          .eq('project_id', projectId)
          .order('sort_order');
      return (res as List)
          .map((e) => ProjectMedia.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Loads media for many projects at once. Returns a map keyed by project id.
  Future<Map<String, List<ProjectMedia>>> getMediaForProjects(
    List<String> projectIds,
  ) async {
    if (projectIds.isEmpty) return {};
    try {
      final res = await _sb
          .from('community_project_media')
          .select()
          .inFilter('project_id', projectIds)
          .order('sort_order');
      final out = <String, List<ProjectMedia>>{};
      for (final row in (res as List)) {
        final m = ProjectMedia.fromJson(row as Map<String, dynamic>);
        out.putIfAbsent(m.projectId, () => []).add(m);
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Uploads a media file (image/video bytes) to Supabase Storage and inserts
  /// a corresponding row into community_project_media. Returns the new media,
  /// or null on failure.
  Future<ProjectMedia?> uploadProjectMedia({
    required String projectId,
    required String mediaType, // 'image' | 'video'
    required Uint8List bytes,
    required String fileExt, // 'jpg', 'png', 'mp4', etc.
    String? caption,
  }) async {
    try {
      final fileName =
          '${const Uuid().v4()}.${fileExt.toLowerCase().replaceAll(".", "")}';
      final storagePath = '$projectId/$fileName';
      final contentType = _contentTypeFor(mediaType, fileExt);

      await _sb.storage
          .from(_mediaBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      final publicUrl = _sb.storage
          .from(_mediaBucket)
          .getPublicUrl(storagePath);

      // Compute next sort_order
      final existing = await _sb
          .from('community_project_media')
          .select('sort_order')
          .eq('project_id', projectId)
          .order('sort_order', ascending: false)
          .limit(1);
      final nextOrder =
          existing.isEmpty
              ? 0
              : ((existing.first['sort_order'] as num?)?.toInt() ?? 0) + 1;

      final inserted =
          await _sb
              .from('community_project_media')
              .insert({
                'project_id': projectId,
                'media_type': mediaType,
                'url': publicUrl,
                'caption': caption,
                'sort_order': nextOrder,
              })
              .select()
              .single();

      return ProjectMedia.fromJson(inserted);
    } catch (_) {
      return null;
    }
  }

  /// Uploads a Display Picture for the project and updates community_projects
  Future<String?> uploadProjectDP({
    required String projectId,
    required Uint8List bytes,
    required String fileExt,
  }) async {
    try {
      final fileName =
          'dp_${const Uuid().v4()}.${fileExt.toLowerCase().replaceAll(".", "")}';
      final storagePath = '$projectId/$fileName';
      final contentType = _contentTypeFor('image', fileExt);

      await _sb.storage
          .from(_mediaBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      final publicUrl = _sb.storage
          .from(_mediaBucket)
          .getPublicUrl(storagePath);

      await _sb
          .from('community_projects')
          .update({'dp_url': publicUrl})
          .eq('id', projectId);

      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a media item (both DB row and the storage object).
  Future<bool> deleteProjectMedia(ProjectMedia media) async {
    try {
      // Best-effort: derive storage path from public url
      final marker = '/$_mediaBucket/';
      final idx = media.url.indexOf(marker);
      if (idx != -1) {
        final path = media.url.substring(idx + marker.length);
        await _sb.storage.from(_mediaBucket).remove([path]);
      }
      await _sb.from('community_project_media').delete().eq('id', media.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Re-orders media for a project according to the given list of ids.
  Future<void> reorderProjectMedia(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      try {
        await _sb
            .from('community_project_media')
            .update({'sort_order': i})
            .eq('id', orderedIds[i]);
      } catch (_) {}
    }
  }

  String _contentTypeFor(String mediaType, String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    if (mediaType == 'video') {
      switch (e) {
        case 'mov':
          return 'video/quicktime';
        case 'webm':
          return 'video/webm';
        default:
          return 'video/mp4';
      }
    }
    switch (e) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
