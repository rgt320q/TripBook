allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.evaluationDependsOn(":app")

    tasks.matching { it.name.contains("generateDebugUnitTestConfig") }.configureEach {
        enabled = false
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

plugins{
    id("com.google.gms.google-services") version "4.3.15" apply false
}
