FROM openjdk:18-bullseye
LABEL maintainer="matt.raspberry@gmail.com"
ARG ACCEPT_EULA
ARG RCON_PASS
ENV RCON_PW=$RCON_PASS
ENV ACCEPTED_EULA=$ACCEPT_EULA
ENV MC_URL="https://launcher.mojang.com/v1/objects/3cf24a8694aca6267883b17d934efacc5e44440d/server.jar"
ENV MC_JAR="minecraft-server.1.18.jar"

WORKDIR /opt/minecraft

RUN addgroup --system minecraft && adduser --system --ingroup minecraft minecraft && \
    mkdir -p /opt/minecraft/world && \
    wget -q -O $MC_JAR $MC_URL && \
    chown -R minecraft:minecraft /opt/minecraft/

COPY --chown=minecraft:minecraft server.properties /opt/minecraft/

RUN sed -i "/^rcon\.password/s/CHANGEME/${RCON_PW}/" /opt/minecraft/server.properties || exit 1

USER minecraft
RUN java -jar $MC_JAR nogui || true
RUN test "$ACCEPTED_EULA" = "true"  && sed -i 's/eula=false/eula=true/' eula.txt || exit 1
EXPOSE 25565 25575
CMD [ "java", "-Xmx2048M", "-Xms2048M", "-jar", "/opt/minecraft/minecraft-server.1.18.jar", "nogui" ]
