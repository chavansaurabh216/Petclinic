FROM openjdk:8
EXPOSE 8082
ADD petclinic.war petclinic.war
ENTRYPOINT ["java","-jar","/petclinic.war"]