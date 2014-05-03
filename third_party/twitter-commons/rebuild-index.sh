#!/usr/bin/env bash

if (( $# != 1 ))
then
  echo "Must provide a sha"
  exit 1
fi

sha=$1

HERE=$(cd $(dirname $(readlink $0 || echo $0)) && pwd)

[[ -d ${HERE}/${sha} ]] || mkdir -p ${HERE}/${sha}


SDIST_ROOT=third_party/twitter-commons/${sha}
BDIST_ROOT=${SDIST_ROOT}/dist


function create_index_file() {
DIR=$1
START=$PWD
cd ${DIR}

OUT=index.html

cat > $OUT << HEADER
<html>
  <head>
    <title>Index of ${DIR}</title>
  </head>
  <body>
    <h1>Index of ${DIR}</h1>
HEADER

for file in *.tar.gz *.zip *.tgz *.whl *.egg
do
  if [ -r "${file}" ]
  then
    echo "    <a href=\"${file}\">${file}</a>" >> $OUT
  fi
done

cat >> $OUT << FOOTER
  </body>
</html>
FOOTER

cd ${START}
}

create_index_file ${SDIST_ROOT}
create_index_file ${BDIST_ROOT}

cd $START
