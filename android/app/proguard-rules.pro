-keep class com.k2fsa.sherpa.onnx.** { *; }
-keep class ai.onnxruntime.** { *; }
# Compose reads the $stable field of these classes at runtime; R8 strips it otherwise (crash opening Tasmee settings).
-keepclassmembers class io.github.m7mdloverrr.quran.** { static int $stable; }
