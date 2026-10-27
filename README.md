# downbit-support

Files [Downbit](https://github.com/egoist/downbit) downloads as it needs them.

## FFmpeg

Downbit converts to formats other than MP4 and M4A with FFmpeg. Without one
on the system, it downloads it the first time from a release here,
`ffmpeg-<version>`, and checks it against the SHA-256 sum built into the app.

Each release holds `ffmpeg-<os>-<arch>.zip` for darwin-arm64, darwin-amd64,
linux-amd64, linux-arm64, windows-amd64 and windows-arm64, each with the
`ffmpeg` executable alone, and `checksums.sha256` of them. They are the
upstream builds, repackaged: [Martin Riedl's](https://ffmpeg.martin-riedl.de)
for macOS and Linux, signed and notarized, and
[BtbN's](https://github.com/BtbN/FFmpeg-Builds) GPL builds of the same
release branch for Windows, each checked against the sum its source
publishes ([`ffmpeg/build.sh`](ffmpeg/build.sh)).

To release a newer FFmpeg, run the **FFmpeg** workflow (Actions → FFmpeg →
Run workflow). It publishes the release of the latest upstream version,
unless there is one, as a prerelease, so that it is never the repository's latest release,, and never
replaces an archive already released. Then
point Downbit at it: the tag and the sums are in
`internal/engine/ffmpeg.go`.

FFmpeg is licensed under the GPL; each release's notes link its source.
