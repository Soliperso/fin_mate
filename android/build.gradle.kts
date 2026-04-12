allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Workaround: AGP 8.x requires a namespace in every library module, and
// Kotlin 2.x enforces consistent JVM targets between Java and Kotlin tasks.
// Some Flutter plugins (e.g. flutter_jailbreak_detection 1.10.0) predate
// both requirements. Fix both here for all library subprojects.
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.findByType(com.android.build.gradle.LibraryExtension::class)
            ?: return@withId
        // Assign missing namespace
        if (android.namespace == null) {
            android.namespace = project.group.toString().ifEmpty {
                project.name.replace("-", ".")
            }
        }
        // Align Java compile target
        android.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_11
            targetCompatibility = JavaVersion.VERSION_11
        }
    }
    plugins.withId("kotlin-android") {
        extensions.findByType(org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension::class)
            ?.compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
