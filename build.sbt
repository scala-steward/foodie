enablePlugins(ScalaJSPlugin)

name := "foodie"

version := "0.1"

scalaVersion := "2.12.4"

libraryDependencies ++= Seq(
  "org.scalacheck" %% "scalacheck" % "1.13.4" % "test",
  "org.typelevel" %% "spire" % "0.14.1",
  "org.scalaz" %% "scalaz-core" % "7.2.19",
  "org.scala-js" %%% "scalajs-dom" % "0.9.1",
  "org.mongodb" %% "casbah" % "3.1.1",
  "ch.qos.logback" % "logback-classic" % "1.2.3",
  "com.github.tototoshi" %% "scala-csv" % "1.3.5"
)

scalaJSUseMainModuleInitializer := true