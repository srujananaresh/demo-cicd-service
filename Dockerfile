FROM openjdk:8
EXPOSE 6060
COPY ./target/demo-cicd-service-0.1.1-SNAPSHOT.jar demo-cicd-service-0.1.1-SNAPSHOT.jar
CMD ["java" , "-jar" , "demo-cicd-service-0.1.1-SNAPSHOT.jar"]