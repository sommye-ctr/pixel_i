import 'package:frontend/core/network/api_client.dart';
import '../models/comment.dart';

class CommentsRepository {
  final ApiClient api;

  CommentsRepository(this.api);

  Future<List<Comment>> fetchTopLevelComments(String photoId) async {
    final res = await api.get<List<dynamic>>('/photos/$photoId/comments/');
    final data = res.data ?? [];
    print(data);
    return data.map((e) => Comment.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<Comment>> fetchReplies(String photoId, String parentId) async {
    final res = await api.get<List<dynamic>>('/comments/$parentId/children/');
    final data = res.data ?? [];
    return data.map((e) => Comment.fromMap(e as Map<String, dynamic>)).toList();
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
