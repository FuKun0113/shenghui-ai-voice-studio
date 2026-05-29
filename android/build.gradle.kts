allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
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
    if (name == "firebase_remote_config") {
        plugins.withId("com.android.library") {
            pluginManager.apply("org.jetbrains.kotlin.android")
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
                .configureEach {
                    compilerOptions {
                        jvmTarget.set(
                            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                        )
                    }
                }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
