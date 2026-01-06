#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services (Optional but recommended to prevent crashing)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }

# Prevent stripping of JSON serialization
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Http
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# General
-dontwarn io.flutter.**
