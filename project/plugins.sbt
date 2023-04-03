addSbtPlugin("com.typesafe.play"    % "sbt-plugin"        % "2.8.19")
addSbtPlugin("com.github.tototoshi" % "sbt-slick-codegen" % "1.4.0")
addSbtPlugin("nl.gn0s1s"            % "sbt-dotenv"        % "3.0.0")

libraryDependencies += "org.postgresql" % "postgresql" % "42.6.0"
