FROM tomcat:10.1-jre21-temurin
COPY target/vehiculosBuild.war /usr/local/tomcat/webapps/vehiculosBuild.war
EXPOSE 8080