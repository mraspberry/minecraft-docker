FROM openjdk:18-buster
LABEL maintainer="matt.raspberry@gmail.com"
ARG ACCEPT_EULA
ARG RCON_PASS
ENV RCON_PW=$RCON_PASS
ENV ACCEPTED_EULA=$ACCEPT_EULA
WORKDIR /opt/minecraft

RUN addgroup --system minecraft && \
    adduser --system --ingroup minecraft minecraft && \
    mkdir -p world && \
    wget -q -O minecraft-server.1.17.1.jar https://launcher.mojang.com/v1/objects/a16d67e5807f57fc4e550299cf20226194497dc2/server.jar && \
    chown -R minecraft:minecraft /opt/minecraft/

COPY --chown=minecraft:minecraft server.properties /opt/minecraft/

RUN sed -i "/^rcon\.password/s/CHANGEME/${RCON_PW}/" /opt/minecraft/server.properties || exit 1

WORKDIR /opt/minecraft
USER minecraft
RUN java -jar minecraft-server.1.17.1.jar nogui || true
RUN [ "$ACCEPTED_EULA" = "true" ] && sed -i 's/eula=false/eula=true/' eula.txt || exit 1
EXPOSE 25565 25575
CMD ["java", "-Xmx2048M", "-Xms2048M", "-jar", "minecraft-server.1.17.1.jar", "nogui"]
