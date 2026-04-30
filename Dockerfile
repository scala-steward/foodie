FROM eclipse-temurin:17-jdk AS build

WORKDIR /app

RUN apt-get update && apt-get install -y curl bash && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://raw.githubusercontent.com/dwijnand/sbt-extras/12394d5/sbt -o /usr/local/bin/sbt && \
    chmod +x /usr/local/bin/sbt

COPY project/build.properties project/
RUN sbt -v sbtVersion

COPY build.sbt ./
COPY project/*.sbt project/*.scala project/
COPY conf/ conf/

RUN sbt update

COPY app/ app/

RUN sbt stage

FROM bellsoft/liberica-runtime-container:jre-17-musl

WORKDIR /opt/docker

COPY --from=build /app/target/universal/stage/ /opt/docker/

RUN chmod +x /opt/docker/bin/foodie && \
    adduser -D -u 1001 appuser

EXPOSE 9000

USER appuser

CMD ["/opt/docker/bin/foodie", "-Dpidfile.path=/dev/null"]
