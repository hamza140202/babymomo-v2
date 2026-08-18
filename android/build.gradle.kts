allprojects {
    repositories {
        google()
        mavenCentral()
    }
    extra.set("flutter", mapOf("ndkVersion" to "27.1.12297006"))
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
    if (project.name != "app") {
        afterEvaluate {
            val androidExt = project.extensions.findByName("android")
            if (androidExt is com.android.build.gradle.BaseExtension) {
                androidExt.compileSdkVersion(35)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
