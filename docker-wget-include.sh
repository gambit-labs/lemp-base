#!/bin/bash

if [[ $# != 2 ]]; then
	cat <<EOF
Usage: $0 [template dockerfile] [output dockerfile]
EOF
fi

SOURCE=$1
TARGET=$2
TARGETDIR=$(dirname $TARGET)

cat ${SOURCE} | sed -e "/WGET/d" > ${TARGET}

while read line; do
	echo ${line}
		line=($line)
		url=${line[1]}
		filename=$(echo ${url} | rev | cut -d/ -f1 | rev)
		curl -sSL ${url} > ${TARGETDIR}/${filename}
done < <(grep "WGET" ${SOURCE})

while read line; do

		linearr=($line)
		url=${linearr[1]}
		echo "INCLUDE ${url}"
		curl -sSL ${url} | sed -e "/FROM/d;/MAINTAINER/d;/EXPOSE/d;/VOLUME/d;/WORKDIR/d;/CMD/d;/ENTRYPOINT/d;" > ${TARGETDIR}/Dockerfile.tmp
		cd ${TARGETDIR} && sed -e "\%${line}% {" -e 'r Dockerfile.tmp' -e 'd' -e '}' -i ${TARGET}
done < <(grep "INCLUDE" ${SOURCE})

sed '/#/d;/^$/d;' -i ${TARGET}
rm ${TARGETDIR}/Dockerfile.tmp
