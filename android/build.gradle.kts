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
subprojects {
    project.evaluationDependsOn(":app")
}

// 强制所有子模块（含第三方插件，例如 file_picker）使用 compileSdk 36，
// 避免个别插件硬编码较低 compileSdk 导致 AAR 元数据校验失败。
subprojects {
    val fixCompileSdk: (Project) -> Unit = { p ->
        val androidExt = p.extensions.findByName("android")
        if (androidExt != null) {
            try {
                androidExt.javaClass
                    .getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    .invoke(androidExt, 36)
            } catch (_: Throwable) {
            }
        }
    }
    if (project.state.executed) {
        fixCompileSdk(project)
    } else {
        project.afterEvaluate(fixCompileSdk)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
