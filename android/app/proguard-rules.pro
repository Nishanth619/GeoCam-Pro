# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Camera Plugin
-keep class io.flutter.plugins.camera.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# SQLite
-keep class com.tekartik.sqflite.** { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# HTTP
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Google Play Core (for deferred components and split installs)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep all Flutter embedding classes
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ─── AdMob Mediation Network ProGuard Rules ──────────────────────────────────

# Meta (Facebook) Audience Network
-keep class com.facebook.** { *; }
-keep interface com.facebook.** { *; }
-dontwarn com.facebook.**
# Suppress missing Facebook infer annotation classes (compile-time only)
-dontwarn com.facebook.infer.annotation.**

# AppLovin
-keep class com.applovin.** { *; }
-keep interface com.applovin.** { *; }
-dontwarn com.applovin.**

# Unity Ads
-keep class com.unity3d.** { *; }
-keep interface com.unity3d.** { *; }
-dontwarn com.unity3d.**
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.services.**
