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
