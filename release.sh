rm -f DOWNLOAD.zip

mkdir release/
mkdir release/DVHistory

cp -r src/* release/DVHistory
cp lovely.toml  release/DVHistory

cd release/
zip -r DOWNLOAD.zip *
mv DOWNLOAD.zip ..
cd ..

rm -rf release
