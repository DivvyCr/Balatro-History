rm -f DOWNLOAD.zip

mkdir release/
mkdir release/DVHistory
mkdir release/DVSettings/

cp -r src/* release/DVHistory
cp lovely.toml  release/DVHistory

cp -r $DVSET_PATH/src/* release/DVSettings
cp $DVSET_PATH/lovely.toml release/DVSettings

cd release/
zip -r DOWNLOAD.zip *
mv DOWNLOAD.zip ..
cd ..

rm -rf release
