# Flutter + Firebase release shrinker keep rules.
# Keep Flutter embedding / engine entry points.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase / Google Play services — reflection-heavy SDKs.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Crashlytics needs source file + line numbers for readable stacks.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter's engine references Play Core's deferred-components (dynamic
# feature module) APIs, but this app doesn't use dynamic feature modules —
# the classes are genuinely absent, not misconfigured, so tell R8 that's OK.
-dontwarn com.google.android.play.core.**
