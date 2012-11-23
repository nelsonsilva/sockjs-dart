#!/bin/bash
PACKAGES="packages"
mkdir -p $PACKAGES

package() {
 name=$1
 version=$2
 url=$3
 echo "Packaging $name v$version"
 echo "{'name':'$name','versions':['$version']}" > $PACKAGES/$name.json
 dir=$PACKAGES/$name/versions
 mkdir -p $dir
 cd $dir
 git clone $url $version
 cp $version/pubspec.yaml $version.yaml
 cd $version
 tar -czf ../$version.tar.gz *
 cd ..
 rm -Rf $version
}

START=$PWD

URL=`git config --get remote.origin.url`

package "sockjs" "0.1.0" $URL

cd $START
