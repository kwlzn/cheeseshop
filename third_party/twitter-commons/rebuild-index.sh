#!/bin/sh

START=$PWD

if (( $# != 1 ))
then
  echo "Must provide a sha"
  exit 1
fi

sha=$1

HERE=$(cd $(dirname $(readlink $0 || echo $0)) && pwd)

([[ -d ${HERE}/{sha} ]] || mkdir -p ${HERE}/${sha}) && cd ${HERE}/${sha}

OUT=index.html

SDIST_ROOT=/third_party/twitter-commons/${sha}

cat > $OUT << HEADER
<html>
  <head>
    <title>Index of $SDIST_ROOT</title>
  </head>
  <body>
    <h1>Index of $SDIST_ROOT</h1>
HEADER

for sdist in *.tar.gz *.zip *.tgz *.whl
do
  if [ -r "$sdist" ]
  then
    echo "    <a href=\"$sdist\">$sdist</a>" >> $OUT
  fi
done

cat >> $OUT << FOOTER
  </body>
</html>
FOOTER

cd $START
