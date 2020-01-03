FROM python:3 AS opsjson_generation

ARG MCUSER
ENV MINECRAFT_USER=$MCUSER
WORKDIR /opt/ops_json_generate
COPY requirements.txt generate_ops_json.py ./
RUN python3 -mpip install --no-cache -r requirements.txt && python3 generate_ops_json.py $MINECRAFT_USER


FROM openjdk:jre-alpine
LABEL maintainer="matt.raspberry@gmail.com"
ARG ACCEPT_EULA
ENV ACCEPTED_EULA=$ACCEPT_EULA

RUN addgroup -S minecraft && adduser -S minecraft -G minecraft && \
    mkdir -p /opt/minecraft && chown -R minecraft:minecraft /opt/minecraft

COPY --chown=minecraft:minecraft server.properties /opt/minecraft/
ADD --chown=minecraft:minecraft https://launcher.mojang.com/v1/objects/4d1826eebac84847c71a77f9349cc22afd0cf0a1/server.jar /opt/minecraft/minecraft-server.1.15.1.jar

WORKDIR /opt/minecraft
USER minecraft
RUN java -jar minecraft-server.1.15.1.jar nogui || true
RUN [ "$ACCEPTED_EULA" == "true" ] && sed -i 's/eula=false/eula=true/' eula.txt || exit 1
COPY --chown=minecraft:minecraft --from=opsjson_generation /opt/ops_json_generate/ops.json /opt/minecraft/
EXPOSE 25565
CMD ["java", "-Xmx4096M", "-Xms4096M", "-jar", "minecraft-server.1.15.1.jar", "nogui"]
