find . -type f -size +1G -exec rm -f {} \;
例如，如果要删除所有找到的文件，可以使用 -exec rm {} \;，这会将每个找到的文件名传递给 rm 命令，然后逐个删除文件。

另外，-exec 选项也支持使用 + 终止，例如 -exec rm {} +，这会将所有匹配到的文件名作为参数一次性传递给 rm 命令，提高效率。

find . -type f -size +1G
find . -type f -size +1G -exec rm -f {} +
