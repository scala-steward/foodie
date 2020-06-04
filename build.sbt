name := """foodie"""
organization := "com.example"

version := "1.0-SNAPSHOT"

lazy val root = (project in file(".")).enablePlugins(PlayScala)

scalaVersion := "2.13.2"

//addCompilerPlugin(
//  "org.scalamacros" % "paradise" % "2.1.1" cross CrossVersion.full
//)

val circeVersion = "0.12.3"

libraryDependencies ++= Seq(
  guice,
  "org.scalatestplus.play" %% "scalatestplus-play" % "5.0.0" % Test,
  "com.typesafe.slick" %% "slick" % "3.3.2",
  "com.typesafe.slick" %% "slick-hikaricp" % "3.3.2",
  "org.postgresql" % "postgresql" % "9.4-1206-jdbc42",
  "org.slf4j" % "slf4j-nop" % "1.6.4",
  "io.circe" %% "circe-core" % circeVersion,
  "io.circe" %% "circe-generic" % circeVersion,
  "io.circe" %% "circe-parser" % circeVersion,
  "org.typelevel" %% "spire" % "0.17.0-M1",
  "org.flywaydb" %% "flyway-play" % "6.0.0",
  "com.typesafe.play" %% "play-slick" % "5.0.0",
  "com.typesafe.play" %% "play-slick-evolutions" % "5.0.0",
  "com.dripower" %% "play-circe" % "2712.0",
  "com.davegurnell" %% "bridges" % "0.21.0",
  "com.github.pathikrit" %% "better-files" % "3.9.1"
)

lazy val elmGenerate = Command.command("elmGenerate") { state =>
  "runMain elm.Bridge" :: state
}

commands += elmGenerate

// Adds additional packages into Twirl
//TwirlKeys.templateImports += "com.example.controllers._"

// Adds additional packages into conf/routes
// play.sbt.routes.RoutesKeys.routesImport += "com.example.binders._"
