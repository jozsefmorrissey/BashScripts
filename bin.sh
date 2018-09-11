bashFiles=$(find . -name "*sh" -not -path "*/junk*")
chmod +x $bashFiles
sudo cp $bashFiles /usr/bin/
