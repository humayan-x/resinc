# Image processing in v1.0.1

## Android background worker

`ImageProcessor.kt` runs on a serial Flutter platform-channel background task queue.
The UI sends file paths and settings, not pixel buffers. Each job decodes once,
normalizes EXIF orientation, draws an optional crop onto white, and retains a
native bitmap for JPEG trials. Jobs are serialized to avoid multiplying memory
usage. No intermediate PNG or Dart Lanczos pass is used on Android.

Native sampled decoding reduces large inputs before the working bitmap is built.
The working image is bounded to 4,000,000 pixels and a 2560-pixel longest edge.
The 1080p and 720p presets cap the longest edge at 1920 and 1280 respectively;
small sources are never enlarged. Cropping uses normalized coordinates in the
orientation-corrected image and starts from the original selected photo.

## Byte limits and quality

- KB is decimal: 1 KB = 1000 bytes. Optimization aims 1% below the selected ceiling.
- KB jobs try JPEG qualities 85, 65, and 45, returning the first result that fits.
  This deliberately favors speed over an exhaustive best-quality search.
- If no quality fits, the next scale follows the square root of budget/output
  bytes, clamped to 0.4–0.9 with 5% additional headroom. Retry at the smaller size,
  always scaling from the retained bitmap rather than a previous JPEG.
- Resolution-only jobs encode once at their configured quality (normally 80).
- Crop jobs use the current source file size as their byte ceiling. They can
  reduce quality and dimensions if necessary.
- At most 24 resolution levels are attempted. An impossible limit returns an
  error and removes the partial output.

If EXIF preservation is selected, attributes are written before measuring the
final bytes; orientation and size tags are updated. Stripped exports do not copy
source EXIF. Dart verifies the returned file length and ceiling, and saving or
sharing verifies the file again.

## Metrics and fallback

Original source size survives crop operations, so the reduction figure compares
the exported file with the user-selected original. It is not freed disk space:
the original, gallery export, and local saved copy may all still exist.

The previous Dart/native-plugin pipeline remains the non-Android fallback and
supports its existing unit tests. Android worker behavior has separate native
instrumentation tests and Dart channel-contract tests. Processing duration is
measured per job; no universal latency guarantee is made.

## Validation

Run `flutter test --concurrency=2` and `flutter analyze`. With an Android device
connected, from `android/` run:

```sh
./gradlew :app:connectedDebugAndroidTest -PisolatedImageTests
```

This installs a separate `.imagetest` package. Tests generate their own images,
check orientation, metadata, byte limits, dimensions, and failed-job cleanup,
and log a 12-megapixel fixture's processing duration under `ReSincBenchmark`.

### Device measurement (2026-10-25)

On the connected Android device, the native tests processed a generated
4000×3000 noisy JPEG in the debug test app:

| Operation | Native job time | JPEG attempts | Output bytes |
| --- | ---: | ---: | ---: |
| Crop to the central 80% of each axis | 280 ms | 1 | 1,444,873 |
| Optimize to the 200 KB preset (198,000-byte budget) | 482 ms | 5 | 185,683 |

These measurements cover the native decode-to-output job, not image selection,
preview loading, or gallery export. They are one fixture on one device, not a
before/after benchmark or a universal latency guarantee. All three native
instrumentation tests passed, including orientation/metadata and failed-job
cleanup. The isolated test packages were removed afterwards.
