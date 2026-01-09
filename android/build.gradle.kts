allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
//subprojects {
//    project.configurations.all {
//        resolutionStrategy.eachDependency {
//            // 1. Ép androidx.core về 1.12.0 (Phiên bản rất ổn định)
//            if (requested.group == "androidx.core") {
//                useVersion("1.12.0")
//            }
//
//            // 2. Ép androidx.browser về 1.5.0 (Phiên bản an toàn nhất)
//            if (requested.group == "androidx.browser") {
//                useVersion("1.5.0")
//            }
//
//            // 3. QUAN TRỌNG: Ép androidx.activity về 1.8.0
//            // Để nó không đòi hỏi các thư viện core quá mới gây lỗi
//            if (requested.group == "androidx.activity") {
//                useVersion("1.8.0")
//            }
//        }
//    }
//}