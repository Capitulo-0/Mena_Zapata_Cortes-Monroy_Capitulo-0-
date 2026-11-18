
plugins {
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin") version "2.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Compatibilidad de file_picker 11.0.2 con AGP 9.
// Aplicamos Kotlin explícitamente y alineamos su JVM con Java 17.
subprojects {
    if (name == "file_picker") {
        pluginManager.apply("org.jetbrains.kotlin.android")

        plugins.withId("org.jetbrains.kotlin.android") {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>()
                .configureEach {
                    compilerOptions {
                        jvmTarget.set(
                            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                        )
                    }
                }
        }
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

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
