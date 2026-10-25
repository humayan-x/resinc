# Changelog

## 1.0.1 — 2026-10-25

Android build number: 2.

- Move Android crop and optimization into a native background task queue. Decode once, reuse the bitmap, and avoid intermediate PNG files and large Dart pixel transfers.
- Stop at the first good-quality result that meets the byte ceiling; use measured size to guide downscaling.
- Bound working image dimensions and preview decoding to reduce memory use with large photos.
- Recover interrupted Android photo-picker results at startup.
- Preserve saved history when gallery verification fails. Surface load/delete/clear errors and confirm clearing only after completion.
- Compare cropped exports with the original selected file size. Report local photo storage separately from file-size reduction.
- Keep cropped working files within the source file's byte size. Quality or dimensions may decrease to meet that limit.
- Make Apply Crop text white and simplify the home header to “ReSinc”.

Existing saved entries retain their historical comparison sizes because the original baseline cannot be reconstructed reliably.
