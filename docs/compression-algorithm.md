# Compression algorithm

The byte ceiling is an acceptance condition, not an estimate from JPEG quality.
For KB presets, 1 KB means 1,000 bytes, and the encoding budget is 99% of the
selected limit. Resolution-only presets constrain the longest edge, not bytes.
Custom KB targets below 50 are rejected in the input, model, and service; old
saved targets below 50 are excluded when loaded.

## Implemented plan

1. Decode the original once, using Flutter's image decoder and its orientation
   handling. Flatten transparency onto white for JPEG output.
2. Produce each resolution directly from the original pixels with separable
   Lanczos3. Widen the filter support when reducing dimensions to suppress
   aliasing, normalize weights at borders, and perform filtering in an isolate.
   Cache a lossless PNG for repeated JPEG quality trials at the same resolution.
3. Search native JPEG quality 40–95 at each resolution. If no measured candidate
   fits, reduce dimensions proportionally using a pixel-area estimate and retry,
   for at most 32 levels. Prefer reducing resolution over extreme JPEG artifacts.
4. When requested, copy supported EXIF tags before measuring, normalize orientation
   and dimension tags, and exclude thumbnails. Metadata counts against the budget.
5. Return only a measured candidate within budget. If none fits, report failure
   and delete temporary attempts. Never return an oversized fallback.
6. Carry the selected byte limit with the result. Recheck file length before
   sharing and before gallery export, including the copy sent to the gallery.

The previous code already checked candidate sizes; an oversize reproduction was
not available. The new export checks close a gap where a changed result could
previously be saved or shared without revalidation.

## Sources and rationale

- Android JPEG quality controls the size/quality tradeoff, not an exact byte size:
  https://developer.android.com/reference/android/graphics/Bitmap.CompressFormat
- libvips uses Lanczos3 for its final reduction:
  https://www.libvips.org/API/8.17/method.Image.resize.html
- Pillow describes Lanczos as a truncated-sinc filter considering contributing pixels:
  https://pillow.readthedocs.io/en/stable/handbook/concepts.html

The quality floor, 1% headroom, retry bound, and export checks are application
policy, not guarantees supplied by these libraries. Tests cover size boundaries,
failed encodes, impossible budgets, mutated outputs, filter behavior and the
raster/encoder handoff. Native JPEG and EXIF calls are mocked in host tests;
physical-device testing with large photos, rotated images and metadata-heavy
inputs is still needed. Full-resolution decoding uses memory proportional to
source pixels. Third-party apps may independently re-encode shared images.
