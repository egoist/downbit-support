# downbit-support

Downbit's releases, and the files [Downbit](https://downbit.app)
downloads as it needs them.

## Downbit

Each release `v<version>` holds Downbit's installers, for Macs, and Windows
and Linux on x64 and Arm64, and the signed updates that installed apps
update from. It is the repository's latest release, which apps check.

To release Downbit, bump `version` in its `mygo.json`, tag the commit
`v<version>`, push the tag, and run the **Release** workflow at it:

```sh
gh workflow run release.yml --repo egoist/downbit-support -f ref=v0.1.0
```

It builds the apps from egoist/downbit, signs and notarizes the Mac app,
and uploads them to a draft release. It never publishes the draft: look at
it, then publish it, which makes it the latest release that apps update to:

```sh
gh release edit v0.1.0 --repo egoist/downbit-support --draft=false --latest
```

Its secrets are listed at the top of
[`release.yml`](.github/workflows/release.yml).

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
unless there is one, as a prerelease, so that it is never the repository's latest release, and never
replaces an archive already released. Then
point Downbit at it: the tag and the sums are in
`internal/engine/ffmpeg.go`.

FFmpeg is licensed under the GPL; each release's notes link its source.
