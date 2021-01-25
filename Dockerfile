FROM openjdk:8
EXPOSE 6060



COPY ./target/demo-cicd-service-0.1.1-SNAPSHOT.jar demo-cicd-service-0.1.1-SNAPSHOT.jar
COPY ./env/DOCKER/logback.xml logback.xml
COPY ./env/DOCKER/application.properties application.properties


CMD ["java" , "-jar" , "demo-cicd-service-0.1.1-SNAPSHOT.jar"]