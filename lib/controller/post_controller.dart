import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fafte/base_response/base_response.dart';
import 'package:fafte/controller/auth_controller.dart';
import 'package:fafte/models/comment.dart';
import 'package:fafte/models/like.dart';
import 'package:fafte/models/post.dart';
import 'package:fafte/models/user.dart';
import 'package:fafte/utils/export.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PostController extends ChangeNotifier {
  PostController._privateConstructor();
  static final PostController instance = PostController._privateConstructor();
  final authController = AuthController.instance;
  final storage = FirebaseStorage.instance;
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  PostModel postModel = PostModel.fromJson({});
  LikeModel likeModel = LikeModel.fromJson({});
  CommentModel commentModel = CommentModel.fromJson({});

  XFile? pickedImage;
  String postText = '';
  String commentText = '';

  List<PostModel> listPostModel = [];
  List<UserModel> listUserModel = [];
  List<PostModel> listPostByIdModel = [];
  List<CommentModel> listCommentPost = [];
  List<LikeModel> listLikePost = [];

  clear() {
    pickedImage = null;
    postText = '';
    notifyListeners();
  }

  Future<UserModel> getPoster(String userId) async {
    DocumentSnapshot user =
        await firestore.collection("users").doc(userId).get();
    return UserModel.fromDocument(user);
  }

  Future<void> pickImage() async {
    final imageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    pickedImage = await imageFile;
    notifyListeners();
  }

  Future<BaseResponse> sendPost() async {
    try {
      var urlImage;
      if (pickedImage != null) {
        urlImage = await _uploadImage(File(pickedImage!.path));
      }

      final post = await FirebaseFirestore.instance
          .collection('posts')
          .add(<String, dynamic>{});
      final id = await post.id;
      print(id);

      postModel.postImageUrl = urlImage;
      postModel.id = id;
      postModel.userId = auth.currentUser?.uid;
      postModel.timeStamp = DateTime.now().millisecondsSinceEpoch;
      postModel.postText = postText;
      await createPost(postModel.id!, postModel.toJson());

      return BaseResponse(
        message: 'Success',
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<BaseResponse> getAllPost() async {
    try {
      final posts = await firestore
          .collection("posts")
          .orderBy('timeStamp', descending: true)
          .get();
      final postsFirebase = posts.docs.map((e) => e.data()).toList();
      listPostModel = postsFirebase.map((e) => PostModel.fromJson(e)).toList();

      return BaseResponse(
        message: 'Success',
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<BaseResponse> getAllPostById(String id) async {
    try {
      print(id);
      final posts = await firestore
          .collection("posts")
          .where('userId', isEqualTo: id)
          .get();

      final postsFirebase = posts.docs.map((e) => e.data()).toList();
      listPostByIdModel =
          postsFirebase.map((e) => PostModel.fromJson(e)).toList();
      listPostByIdModel.sort((a, b) => a.timeStamp!.compareTo(b.timeStamp!));

      notifyListeners();
      return BaseResponse(
        message: 'Success',
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<String> _uploadImage(File pickedImage) async {
    final storageRef = storage
        .ref()
        .child('posts/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = storageRef.putFile(pickedImage);
    await uploadTask.whenComplete(() => null);
    return storageRef.getDownloadURL();
  }

  Future<void> createPost(String id, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(id).set(data);
    } catch (e) {
      print(e);
    }
  }

  Future<BaseResponse> likePost(String postId) async {
    try {
      final like = await FirebaseFirestore.instance
          .collection('likes')
          .add(<String, dynamic>{});
      final id = await like.id;
      likeModel.id = id;
      likeModel.userId = auth.currentUser?.uid;
      likeModel.postId = postId;
      likeModel.timestamp = DateTime.now().millisecondsSinceEpoch;
      await FirebaseFirestore.instance
          .collection('likes')
          .doc(id)
          .set(likeModel.toJson());

      return BaseResponse(
        message: id,
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<BaseResponse> unLikePost(String likeId) async {
    try {
      await FirebaseFirestore.instance.collection('likes').doc(likeId).delete();

      return BaseResponse(
        message: 'Success',
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<BaseResponse> getLikePost() async {
    try {
      final like = await FirebaseFirestore.instance.collection('likes').get();
      print(like);
      final likesPostFirebase = like.docs.map((e) => e.data()).toList();
      listLikePost =
          likesPostFirebase.map((e) => LikeModel.fromJson(e)).toList();

      return BaseResponse(
        message: 'Success',
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<BaseResponse> commentPost(String postId) async {
    try {
      final comment = await FirebaseFirestore.instance
          .collection('comments')
          .add(<String, dynamic>{});
      final id = await comment.id;
      commentModel.id = id;
      commentModel.userId = auth.currentUser?.uid;
      commentModel.postId = postId;
      commentModel.timestamp = DateTime.now().millisecondsSinceEpoch;
      commentModel.commentText = commentText;
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(id)
          .set(commentModel.toJson());

      return BaseResponse(
        message: 'Success',
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<BaseResponse> getCommentPostById(String postId) async {
    try {
      final posts = await firestore
          .collection("comments")
          .where('postId', isEqualTo: postId)
          .get();

      final postsFirebase = posts.docs.map((e) => e.data()).toList();
      listCommentPost =
          postsFirebase.map((e) => CommentModel.fromJson(e)).toList();
      listCommentPost.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
      notifyListeners();
      return BaseResponse(
        message: 'Success',
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<BaseResponse> getAllCommentPost() async {
    try {
      final posts = await firestore.collection("comments").get();

      final postsFirebase = posts.docs.map((e) => e.data()).toList();
      listCommentPost =
          postsFirebase.map((e) => CommentModel.fromJson(e)).toList();
      listCommentPost.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
      notifyListeners();
      return BaseResponse(
        message: 'Success',
        success: true,
      );
    } catch (error) {
      return BaseResponse(
        message: error.toString(),
        success: false,
      );
    }
  }
}