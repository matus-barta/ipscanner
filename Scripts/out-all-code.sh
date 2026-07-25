echo "Here is output of tree command to list all files and after that content of the all swift files, you can indentify them with file name at the top of the files in comment" > out.txt
tree .. >> out.txt
find .. -type f -name "*.swift" -exec cat {} + >> out.txt
