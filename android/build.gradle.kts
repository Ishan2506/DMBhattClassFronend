allprojects {
    repositories {
        google()
        mavenCentral()
        // Fallback for older artifacts
        maven { url = uri("https://jitpack.io") }
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

    // Fix for plugins not specifying namespace (AGP 8.0+) and mismatching Java targets
    val configureAndroidExtension = {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null) {
                if (android.namespace == null) {
                    android.namespace = project.group.toString()
                }
            }
        }
    }

    if (project.state.executed) {
        configureAndroidExtension()
    } else {
        project.afterEvaluate {
            configureAndroidExtension()
        }
    }

    val configureTasks = {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }

    if (project.state.executed) {
        configureTasks()
    } else {
        project.afterEvaluate {
            configureTasks()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}