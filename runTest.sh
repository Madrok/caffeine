#!/bin/bash
RED='\033[0;31m'
NC='\033[0m' # No Color

HAXE_STD_PATH=~/devel/caffeine/std /usr/local/bin/haxe --main $1 testCommon.hxml > /dev/null || exit 1

echo -e "${RED}neko${NC}..." 
neko bin/main.n

echo -e "${RED}cpp${NC}..."
./bin/cpp/$1-debug  

echo -e "${RED}hashlink${NC}..."
hl bin/main.hl

echo -e "${RED}java${NC}..."
java -jar bin/java/TestSocket-Debug.jar 
