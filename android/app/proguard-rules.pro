# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent R8 from stripping Flutter plugin registrations
-if class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
-keep,allowshrinking,allowobfuscation class <1>

# Flutter Deferred Components (Play Core is optional in Flutter)
-dontwarn com.google.android.play.core.**

# flutter_image_compress
-keep class com.fluttercandies.flutter_image_compress.** { *; }
-dontwarn com.fluttercandies.flutter_image_compress.**
