import 'dart:async';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/src/services/supabase_client.dart';
import 'package:cczu_helper/models/db_models.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeahousePage extends StatefulWidget {
  const TeahousePage({super.key});

  @override
  State<StatefulWidget> createState() => TeahousePageState();
}

class TeahousePageState extends State<TeahousePage> {
  List<PostModel> posts = [];
  int page = 1;
  int pageSize = 20;
  bool loading = false;
  bool hasMore = true;
  Map<String, int> likeCounts = {};
  Set<String> likedPosts = {};

  String? bannerUrl;
  late final ScrollController _scrollController;
  final Map<String, double> _likeScales = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >= _scrollControllerMaxScrollThreshold()) {
          if (!loading && hasMore) loadMore();
        }
      });
    fetchPosts(p: 1);
    _fetchBanner();
  }

  Future<void> _fetchBanner() async {
    final b = await SupabaseService.getActiveBanner();
    if (!mounted) return;
    setState(() {
      bannerUrl = b;
    });
  }

  // small helper to avoid long line in patch context; evaluated at runtime
  double _scrollControllerMaxScrollThreshold() {
    // when near bottom (200 px)
    return _scrollController.hasClients ? (_scrollController.position.maxScrollExtent - 200.0) : double.infinity;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void fetchPosts({int? p, bool append = false}) {
    final ctx = context;
    setState(() {
      loading = true;
      page = p ?? page;
    });
    SupabaseService.getPosts(page: page, pageSize: pageSize).then((res) {
      if (!mounted) return;
      setState(() {
        if (append) {
          posts.addAll(res);
        } else {
          posts = res;
        }
        hasMore = res.length >= pageSize;
        loading = false;
      });
      // fetch like counts and user's liked posts for visible posts
      final ids = posts.map((e) => e.id).toList();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      SupabaseService.getLikeCounts(ids).then((m) {
        if (!mounted) return;
        setState(() {
          likeCounts = m;
        });
      }).catchError((_) {});
      if (userId.isNotEmpty) {
        SupabaseService.getLikedPostIdsForUser(userId, ids).then((s) {
          if (!mounted) return;
          setState(() {
            likedPosts = s;
          });
        }).catchError((_) {});
      }
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ComplexDialog.instance.text(context: ctx, content: Text('获取失败: $e'));
      });
    });
  }

  void loadMore() {
    if (loading || !hasMore) return;
    setState(() {
      page += 1;
    });
    fetchPosts(append: true);
  }

  Future<void> _editPostDialog(PostModel p) async {
    final titleController = TextEditingController(text: p.title);
    final contentController = TextEditingController(text: p.content);
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑帖子'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(hintText: '标题')),
            TextField(controller: contentController, decoration: const InputDecoration(hintText: '内容')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          FilledButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await SupabaseService.editPost(p.id, title: titleController.text.trim(), content: contentController.text.trim());
                nav.pop(true);
              },
              child: const Text('保存'))
        ],
      ),
    );
    if (res == true) fetchPosts(p: 1);
  }

  Future<void> _toggleLike(PostModel p) async {
    final ctx = context;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      ComplexDialog.instance.text(context: ctx, content: const Text('请先登录后再点赞'));
      return;
    }
    final currentlyLiked = likedPosts.contains(p.id);
    // optimistic update + small scale animation
    setState(() {
      if (currentlyLiked) {
        likedPosts.remove(p.id);
        likeCounts[p.id] = (likeCounts[p.id] ?? 1) - 1;
      } else {
        likedPosts.add(p.id);
        likeCounts[p.id] = (likeCounts[p.id] ?? 0) + 1;
      }
      _likeScales[p.id] = 1.4;
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _likeScales[p.id] = 1.0;
      });
    });

    try {
      await SupabaseService.toggleLike(p.id, userId, !currentlyLiked);
    } catch (e) {
      // revert on error
      setState(() {
        if (currentlyLiked) {
          likedPosts.add(p.id);
          likeCounts[p.id] = (likeCounts[p.id] ?? 0) + 1;
        } else {
          likedPosts.remove(p.id);
          likeCounts[p.id] = (likeCounts[p.id] ?? 1) - 1;
        }
      });
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ComplexDialog.instance.text(context: ctx, content: Text('点赞操作失败: $e'));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('茶馆')),
      body: Column(
        children: [
          if (bannerUrl != null)
            SizedBox(
              width: double.infinity,
              height: 140,
              child: GestureDetector(
                onTap: () {},
                child: Image.network(
                  bannerUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Expanded(
            child: AdaptiveView(
              child: RefreshIndicator(
                onRefresh: () async {
                  page = 1;
                  fetchPosts(p: 1);
                  await Future.doWhile(() => Future.delayed(const Duration(milliseconds: 50), () => loading));
                },
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: posts.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index >= posts.length) {
                      if (loading) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                      return hasMore ? const SizedBox.shrink() : const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('没有更多了')));
                    }
                    final p = posts[index];
                    final likeCount = likeCounts[p.id] ?? 0;
                    final liked = likedPosts.contains(p.id);

                    return ListTile(
                      leading: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: _likeScales[p.id] ?? 1.0,
                            child: IconButton(
                              icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
                              onPressed: () => _toggleLike(p),
                            ),
                          ),
                          Text('$likeCount'),
                        ],
                      ),
                      title: Text(p.title),
                      subtitle: Text(p.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _editPostDialog(p);
                          if (v == 'delete') {
                            SupabaseService.deletePost(p.id).then((_) => fetchPosts(p: 1));
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('编辑')),
                          const PopupMenuItem(value: 'delete', child: Text('删除')),
                        ],
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            final sheetCtx = context;
                            List<CommentModel> comments = [];
                            TextEditingController commentController = TextEditingController();

                            // We'll define loadComments inside StatefulBuilder so we can use its setState safely
                            return StatefulBuilder(builder: (context, setState) {
                              void loadComments() {
                                SupabaseService.getComments(p.id).then((res) {
                                  setState(() {
                                    comments = res;
                                  });
                                }).catchError((e) {
                                  if (!mounted) return;
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    ComplexDialog.instance.text(context: sheetCtx, content: Text('获取评论失败: $e'));
                                  });
                                });
                              }

                              // initial load
                              loadComments();

                              return Padding(
                                padding: MediaQuery.of(context).viewInsets,
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.75,
                                  child: Column(
                                    children: [
                                      ListTile(title: Text(p.title), subtitle: Text(p.content)),
                                      const Divider(),
                                      Expanded(
                                        child: comments.isEmpty
                                            ? const Center(child: Text('暂无评论'))
                                            : ListView.separated(
                                                itemCount: comments.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1),
                                                itemBuilder: (context, idx) {
                                                  final c = comments[idx];
                                                  return ListTile(
                                                      title: Text(c.userId ?? '匿名'),
                                                      subtitle: Text(c.content),
                                                      trailing: Text(c.createdAt ?? ''));
                                                },
                                              ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(controller: commentController, decoration: const InputDecoration(hintText: '输入评论')),
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  if (commentController.text.trim().isEmpty) return;
                                                  final content = commentController.text;
                                                  SupabaseService.createComment(p.id, content).then((_) {
                                                    commentController.clear();
                                                    loadComments();
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(sheetCtx).showSnackBar(const SnackBar(content: Text('评论发送成功')));
                                                    });
                                                  }).catchError((e) {
                                                    if (!mounted) return;
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (!mounted) return;
                                                      ComplexDialog.instance.text(context: sheetCtx, content: Text('评论失败: $e'));
                                                    });
                                                  });
                                                },
                                                icon: const Icon(Icons.send)),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          TextEditingController titleController = TextEditingController();
          TextEditingController contentController = TextEditingController();
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('发布新帖'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: titleController, decoration: const InputDecoration(hintText: '标题')),
                        TextField(controller: contentController, decoration: const InputDecoration(hintText: '内容')),
                      ],
                    ),
                    actions: [
                      FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
                      FilledButton(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
                            final dlgCtx = context;
                            final t = titleController.text.trim();
                            final c = contentController.text.trim();
                            SupabaseService.createPost(t, c, categoryId: 1).then((_) {
                              fetchPosts(p: 1);
                            }).catchError((e) {
                              if (!mounted) return;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                ComplexDialog.instance.text(context: dlgCtx, content: Text('发布失败: $e'));
                              });
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('发布'))
                    ],
                  ));
        },
        child: const Icon(Icons.create),
      ),
    );
  }
}

