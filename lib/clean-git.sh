DIR=$1
DIR=${DIR:="."}

( find $DIR -type d -name .git ) | xargs rm -rfv
