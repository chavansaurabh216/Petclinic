FROM openjdk:8
EXPOSE 8082
WORKDIR /opt
ADD /tmp/docker-build/petclinic.war /opt/petclinic.war
ENTRYPOINT ["java","-jar","petclinic.war"]