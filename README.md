# Calibre Index

Calibre Index is a mobile companion for browsing and downloading books from a [Calibre](https://calibre-ebook.com/) library stored in Dropbox. It is a redesigned continuation of [Calibre Carte](https://github.com/Exlaza/CalibreCarte), originally created by Ekansh Jain and Prerna Dave.

This is an independent project. It is not affiliated with or endorsed by the Calibre or Dropbox projects.

## Features

- **Material 3 design:** adapts to Android's system color palette when available, with light and dark themes.
- **Search:** find books by title, author, or tags. Choose the active search field in Settings.
- **Flexible browsing:** switch between grid and list layouts, sort by title or author, and choose ascending or descending order.
- **Book details:** view metadata and description, move between books, and download or open available formats.
- **Dropbox libraries:** find Calibre libraries in your Dropbox, choose which library to browse, and refresh its metadata.
- **Offline reading:** save ebook files in a chosen download folder and open them with a compatible app.

## Run locally

Fetch the project dependencies:

```shell
flutter pub get
```

Create and configure your own Dropbox app, then run with its app key:

```shell
flutter run --dart-define=DROPBOX_APP_KEY=YOUR_APP_KEY
```

Builds without `DROPBOX_APP_KEY` can run, but cannot connect to Dropbox.

## Configure Dropbox

1. Open the [Dropbox App Console](https://www.dropbox.com/developers/apps) and create an app with **Scoped access**.
2. Choose **Full Dropbox** access so the app can search your Dropbox for Calibre library metadata.
3. In the app's **Permissions** tab, enable `files.metadata.read` and `files.content.read`, then apply the changes.
4. In **Settings** > **OAuth 2** > **Redirect URIs**, register this exact URI:

   ```text
   http://localhost:53682/
   ```

5. Copy the app key from the app's Settings page. Use it with `--dart-define=DROPBOX_APP_KEY=YOUR_APP_KEY` when running or building the app.

Calibre Index uses Dropbox's authorization-code flow with PKCE; an app secret is not required. The redirect URI must match exactly.

## Build an Android APK

For a debug APK:

```shell
flutter build apk --debug --dart-define=DROPBOX_APP_KEY=YOUR_APP_KEY
```

For a release APK:

```shell
flutter build apk --release --dart-define=DROPBOX_APP_KEY=YOUR_APP_KEY
```

## Credits and license

Calibre Index is based on the original [Calibre Carte project](https://github.com/Exlaza/CalibreCarte) by **Ekansh Jain** and **Prerna Dave**. This repository retains the original MIT license and copyright notices below.

Calibre is copyright Kovid Goyal and its contributors. Dropbox is a trademark of Dropbox, Inc. Neither project sponsors or endorses Calibre Index.

### MIT License

Copyright (c) 2019 Ekansh Jain

Copyright (c) 2019 Prerna Dave

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
