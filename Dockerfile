FROM openjdk:jre-alpine
LABEL maintainer="matt.raspberry@gmail.com"
ARG ACCEPT_EULA
ARG RCON_PASS
ENV RCON_PW=$RCON_PASS
ENV ACCEPTED_EULA=$ACCEPT_EULA

RUN addgroup -S minecraft && adduser -S minecraft -G minecraft && \
    mkdir -p /opt/minecraft/world && apk add --no-cache wget && \
    wget -q -O /opt/minecraft/minecraft-server.1.16.5.jar https://launcher.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar && \
    chown -R minecraft:minecraft /opt/minecraft/

COPY --chown=minecraft:minecraft server.properties /opt/minecraft/

RUN sed -i "/^rcon\.password/s/CHANGEME/${RCON_PW}/" /opt/minecraft/server.properties || exit 1

WORKDIR /opt/minecraft
USER minecraft
RUN java -jar minecraft-server.1.16.5.jar nogui || true
RUN [ "$ACCEPTED_EULA" == "true" ] && sed -i 's/eula=false/eula=true/' eula.txt || exit 1
EXPOSE 25565 25575
CMD ["java", "-Xmx2048M", "-Xms2048M", "-jar", "minecraft-server.1.16.5.jar", "nogui"]
