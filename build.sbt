name := """foodie"""
organization := "io.danilenko"

version := "1.0-SNAPSHOT"

lazy val root = (project in file(".")).enablePlugins(PlayScala)

scalaVersion := "2.13.2"

val circeVersion = "0.14.2"

libraryDependencies ++= Seq(
  guice,
  "com.typesafe.slick"   %% "slick"           % "3.3.3",
  "com.typesafe.slick"   %% "slick-hikaricp"  % "3.3.3",
  "org.postgresql"        % "postgresql"      % "42.3.6",
  "ch.qos.logback"        % "logback-classic" % "1.2.11",
  "io.circe"             %% "circe-core"      % circeVersion,
  "io.circe"             %% "circe-generic"   % circeVersion,
  "io.circe"             %% "circe-parser"    % circeVersion,
  "org.typelevel"        %% "spire"           % "0.17.0-M1",
  "org.flywaydb"         %% "flyway-play"     % "7.20.0",
  "com.typesafe.play"    %% "play-slick"      % "5.0.2",
  "com.dripower"         %% "play-circe"      % "2814.2",
  "com.davegurnell"      %% "bridges"         % "0.24.0",
  "com.github.pathikrit" %% "better-files"    % "3.9.1"
)

lazy val elmGenerate = Command.command("elmGenerate") { state =>
  "runMain elm.Bridge" :: state
}

commands += elmGenerate
