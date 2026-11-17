import 'package:calibre_carte/helpers/book_downloader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a normalized Dropbox book path', () {
    expect(
      BookDownloader.buildDropboxFilePath(
        '/Calibre Library/',
        '/Author/Book/',
        'book.epub',
      ),
      '/Calibre Library/Author/Book/book.epub',
    );
  });

  test('builds a Dropbox path when there is no relative book folder', () {
    expect(
      BookDownloader.buildDropboxFilePath('/Books/', null, 'book.pdf'),
      '/Books/book.pdf',
    );
  });
}
