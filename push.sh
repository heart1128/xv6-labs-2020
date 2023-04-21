#!/bin/zsh

# $0是文件名
# 添加文件，第一个参数是添加的文件
git add $1

# 提交。第二个参数是注释
git commit -m $2

# 上传，第三个参数是分支
git push -u origin $3
