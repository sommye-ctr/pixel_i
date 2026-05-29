import 'package:frontend/core/network/api_client.dart';
import '../models/comment.dart';

import '../../../core/network/paginated_response.dart';

class CommentsRepository {
  final ApiClient api;

  CommentsRepository(this.api);

  Future<PaginatedResponse<Comment>> fetchTopLevelComments(String photoId, {String? url}) async {
    final targetUrl = url ?? '/photos/$photoId/comments/';
    final res = await api.get<Map<String, dynamic>>(targetUrl);
    final data = res.data ?? <String, dynamic>{};
    return PaginatedResponse.fromMap(data, Comment.fromMap);
  }

  Future<List<Comment>> fetchReplies(String photoId, String parentId) async {
    final res = await api.get<Map<String, dynamic>>('/comments/$parentId/children/');
    final data = res.data ?? <String, dynamic>{};
    final page = PaginatedResponse.fromMap(data, Comment.fromMap);
    return page.results;
  }

  Future<Comment> sendComment(
    String photoId,
    String text, {
    String? parentId,
  }) async {
    final body = <String, dynamic>{'content': text};
    if (parentId != null) body['parent_comment'] = parentId;
    final res = await api.post<Map<String, dynamic>>(
      '/photos/$photoId/comments/',
      data: body,
    );
    final data = res.data ?? <String, dynamic>{};
    return Comment.fromMap(data);
  }
}
