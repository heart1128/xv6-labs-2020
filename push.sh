#!/bin/zsh

# 添加文件，第一个参数是添加的文件
git add $0

# 提交。第二个参数是注释
git commit -m $1

# 上传，第三个参数是分支
git push -u origin $2
