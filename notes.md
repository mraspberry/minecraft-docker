# Journey Minecraft running in docker with the autopilot pattern

Started with a straightforward Dockerfile to get Minecraft running
```Dockerfile
FROM openjdk:jre-alpine
LABEL maintainer="matt.raspberry@gmail.com"

RUN addgroup -S minecraft && adduser -S minecraft -G minecraft && \
    mkdir -p /opt/minecraft && chown -R minecraft:minecraft /opt/minecraft

COPY --chown=minecraft:minecraft eula.txt server.properties /opt/minecraft/
ADD --chown=minecraft:minecraft https://launcher.mojang.com/v1/objects/4d1826eebac84847c71a77f9349cc22afd0cf0a1/server.jar /opt/minecraft/minecraft-server.1.15.1.jar

WORKDIR /opt/minecraft
USER minecraft
EXPOSE 25565
CMD ["java", "-Xmx4096M", "-Xms4096M", "-jar", "minecraft-server.1.15.1.jar", "nogui"]
```

With the above, minecraft was successfully running in Docker, creating a new world with every start of the container. Several problems with this
1. world not persistent
2. Minecraft console doesn't work via `docker attach`
3. Because of #2, nobody has op permissions and can't be granted them

I went to tackling #3 first. I found that Mojang has an [API](https://wiki.vg/Mojang_API) so I figured it would be simple enough to generate the ops.json in the build of the image
using Docker's multi-stage builds. As a refresher, here is the format of the ops.json file with some reasonable defaults:

##### ops.json template
```json
[
  {
    "uuid": "PLAYER_UUID",
    "name": "PLAYER_USERNAME",
    "level": 4,
    "bypassesPlayerLimit": false
  }
]
```

Simply because it's the quickest, I chose to use python to generate the ops.json. Code:
##### generate_ops_json.py
```python
#!/usr/bin/env python3

import argparse
import json
import sys
import requests

def main():
    parser = argparse.ArgumentParser(description='Generate an initial ops.json for the specified minecraft user')
    parser.add_argument('username', metavar='MINECRAFT_USERNAME', help='Minecraft username to make an op')
    args = parser.parse_args()

    headers = { 'Content-Type': 'application/json' }
    res = requests.post('https://api.mojang.com/profiles/minecraft', json=[args.username,], headers=headers)
    res.raise_for_status()
    data = res.json()
    print(json.dumps(data, indent=2))
    if not data:
        sys.exit(f'No user information found for username {args.username}\n')
    ops_config = [{
        "uuid": data[0]['id'],
        "name": data[0]['name'],
        "level": 4,
        "bypassesPlayerLimit": False,
        },]
    with open('ops.json', 'w') as fh:
        json.dump(ops_config, fh, indent=2)

if __name__ == '__main__':
    main()
```
And the Dockerfile modified to use it:
```Dockerfile
FROM python:3 AS opsjson_generation

ARG MCUSER
ENV MINECRAFT_USER=$MCUSER
WORKDIR /opt/ops_json_generate
COPY requirements.txt generate_ops_json.py ./
RUN python3 -mpip install --no-cache -r requirements.txt && python3 generate_ops_json.py $MINECRAFT_USER


FROM openjdk:jre-alpine
LABEL maintainer="matt.raspberry@gmail.com"

RUN addgroup -S minecraft && adduser -S minecraft -G minecraft && \
    mkdir -p /opt/minecraft && chown -R minecraft:minecraft /opt/minecraft
COPY --chown=minecraft:minecraft --from=opsjson_generation /opt/ops_json_generate/ops.json /opt/minecraft/

COPY --chown=minecraft:minecraft eula.txt server.properties /opt/minecraft/
ADD --chown=minecraft:minecraft https://launcher.mojang.com/v1/objects/4d1826eebac84847c71a77f9349cc22afd0cf0a1/server.jar /opt/minecraft/minecraft-server.1.15.1.jar

WORKDIR /opt/minecraft
USER minecraft
EXPOSE 25565
CMD ["java", "-Xmx4096M", "-Xms4096M", "-jar", "minecraft-server.1.15.1.jar", "nogui"]
```
