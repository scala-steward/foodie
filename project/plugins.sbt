addSbtPlugin("org.playframework"    % "sbt-plugin"        % "3.0.6")
addSbtPlugin("com.github.tototoshi" % "sbt-slick-codegen" % "2.2.0")
addSbtPlugin("nl.gn0s1s"            % "sbt-dotenv"        % "3.1.0")

libraryDependencies += "org.postgresql" % "postgresql" % "42.7.5"

ThisBuild / libraryDependencySchemes += "org.scala-lang.modules" %% "scala-xml" % VersionScheme.Always
