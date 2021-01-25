FROM openjdk:8-jre-alpine
EXPOSE 0000

ARG APP_NAME
ARG APP_VERSION

ENV APP_HOME /opt/SP/apps/${APP_NAME}

ENV JAVA_OPTS="-Ddebug=true -Xms1024m -Xmx3072m -XX:ParallelGCThreads=15 -Dlogback.configurationFile=logback.xml -Djdk.tls.allowUnsafeServerCertChange=true"

RUN mkdir -p $APP_HOME

WORKDIR $APP_HOME

VOLUME /var/logs

COPY ./target/${APP_NAME}-${APP_VERSION}.jar app.jar
COPY ./env/DOCKER/logback.xml logback.xml
COPY ./env/DOCKER/application.properties application.properties

ENTRYPOINT ["sh", "-c"]
CMD ["exec java $JAVA_OPTS -jar app.jar"]