FROM openjdk:jre-alpine
LABEL maintainer="matt.raspberry@gmail.com"

RUN addgroup -S minecraft && adduser -S minecraft -G minecraft && \
    mkdir -p /opt/minecraft && chown -R minecraft:minecraft /opt/minecraft

COPY --chown=minecraft:minecraft eula.txt server.properties whitelist.json /opt/minecraft/
ADD --chown=minecraft:minecraft https://launcher.mojang.com/v1/objects/4d1826eebac84847c71a77f9349cc22afd0cf0a1/server.jar /opt/minecraft/minecraft-server.1.15.1.jar

WORKDIR /opt/minecraft
USER minecraft
EXPOSE 22565 22565
CMD ["java", "-Xmx512M", "-Xms512M", "-jar", "minecraft-server.1.15.1.jar", "nogui"]
#CMD ["java", "-Xmx4096M", "-Xms4096M", "-jar", "minecraft-server.1.15.1.jar", "nogui"]
