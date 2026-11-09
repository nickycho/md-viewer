# MDViewer

MDViewer is a native macOS app for editing Markdown documents and viewing a rendered preview.

## Features

- Open and save Markdown (`.md`) and plain text documents with the macOS document browser.
- Switch between a monospaced text editor and a rendered Markdown preview.
- Render Markdown with [marked](https://github.com/markedjs/marked) and highlight code with [highlight.js](https://github.com/highlightjs/highlight.js).
- Increase or decrease the editor and preview text size with **⌘=** and **⌘−**. The selected size is saved between launches.

## Requirements

- macOS 14 or later
- Swift 6 toolchain (included with Xcode or the Xcode Command Line Tools)
- `make` and `curl` for the Makefile commands

## Build and run

Clone the repository and build the app bundle:

```sh
git clone https://github.com/nickycho/md-viewer.git
cd md-viewer
make bundle
open MDViewer.app
```

To run the app directly with Swift Package Manager:

```sh
swift run
```

The Markdown renderer and syntax-highlighting assets are included in the repository. To download the pinned upstream copies again, run `make deps`.

## Development commands

```sh
make build   # Build the release executable
make bundle  # Build and create MDViewer.app
make open    # Build, bundle, and open the app
make clean   # Remove generated build and app bundle files
```
