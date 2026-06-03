import 'dart:io';
import '../core/database_helper.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../models/page_model.dart';

class DocumentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Folder>> getFolders() => _dbHelper.getAllFolders();

  Future<int> createFolder(String name, {DateTime? expiresAt}) {
    final folder = Folder(name: name, createdAt: DateTime.now(), expiresAt: expiresAt);
    return _dbHelper.insertFolder(folder);
  }

  Future<List<Document>> getRecentDocuments() => _dbHelper.getRecentDocuments();

  Future<List<Document>> searchDocuments(String query) => _dbHelper.searchDocuments(query);

  Future<void> cleanupExpiredFolders() async {
    final expired = await _dbHelper.getExpiredFolders();
    for (var folder in expired) {
      await deleteFolder(folder.id!);
    }
  }

  Future<List<Document>> getDocumentsInFolder(int folderId) =>
      _dbHelper.getDocumentsByFolder(folderId);

  Future<int> createDocument(int folderId, String name) {
    final doc = Document(
      folderId: folderId,
      name: name,
      createdAt: DateTime.now(),
    );
    return _dbHelper.insertDocument(doc);
  }

  Future<int> addPage(PageModel page) => _dbHelper.insertPage(page);

  Future<List<PageModel>> getPages(int documentId) =>
      _dbHelper.getPagesByDocument(documentId);

  Future<void> deleteDocument(int id) async {
    final pages = await getPages(id);
    for (var page in pages) {
      final file = File(page.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _dbHelper.deleteDocument(id);
  }

  Future<int> deleteFolder(int id) async {
    // Note: If folder deletion should also delete all document files within it:
    final docs = await _dbHelper.getDocumentsByFolder(id);
    for (var doc in docs) {
      await deleteDocument(doc.id!);
    }
    return _dbHelper.deleteFolder(id);
  }

  Future<int> updatePage(PageModel page) => _dbHelper.updatePage(page);

  Future<void> replacePageImage(PageModel oldPage, String newPath) async {
    // 1. Delete old file
    final oldFile = File(oldPage.imagePath);
    if (await oldFile.exists()) {
      await oldFile.delete();
    }
    // 2. Update DB with new path
    final updatedPage = oldPage.copyWith(imagePath: newPath);
    await _dbHelper.updatePage(updatedPage);
  }

  Future<void> deletePage(PageModel page) async {
    final file = File(page.imagePath);
    if (await file.exists()) {
      await file.delete();
    }
    await _dbHelper.deletePage(page.id!);
  }
}