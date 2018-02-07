enablePlugins(ScalaJSPlugin)

name := "foodie"

version := "0.1"

scalaVersion := "2.12.4"

libraryDependencies ++= Seq(
  "org.scalacheck" %% "scalacheck" % "1.13.4" % "test",
  "org.typelevel" %% "spire" % "0.14.1",
  "org.scalaz" %% "scalaz-core" % "7.2.19"
)

scalaJSUseMainModuleInitializer := true