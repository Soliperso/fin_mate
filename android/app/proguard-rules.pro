# ML Kit text recognition — keep optional script modules referenced at runtime
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Supabase / Ktor HTTP client
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Cryptography (pgcrypto / BouncyCastle used for TOTP)
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# JSON serialization — preserve annotated fields
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Prevent stripping Serializable implementations
-keep class * implements java.io.Serializable { *; }

# Sentry crash reporting — keep stack trace info
-keepattributes LineNumberTable,SourceFile
-renamesourcefileattribute SourceFile
