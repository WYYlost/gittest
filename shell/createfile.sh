#!/bin/bash

# 设置文件数量和大小
file_count=10
file_size=1G

# 循环创建文件
for ((i=1; i<=$file_count; i++))
do
  filename="output_file_$i.txt"
  fallocate -l $file_size $filename
  echo "Created $filename with size $file_size"
done
