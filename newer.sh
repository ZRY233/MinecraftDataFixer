#!/bin/bash

serverRootDir="puremc"
prefix="died"
targetDir="experience"
screenName="pureMC-SCREEN"
serverJar="server.jar"

rconPort=`cat server.properties |grep rcon.port|awk -F'=' '{print $2}'`
levelName=`cat server.properties|grep level-name|awk -F'=' '{print $2}'`
echo "rconPort: $rconPort"
echo "levelName: $levelName"

# -p 是rcon服务端密码

while getopts 'p:' opt;
do
    rconPassword=$OPTARG
done

if test "$rconPassword" == ""; then
    echo "使用-p来指定rcon密码,将密码默认为password"
    rconPassword="password"
fi

if mcrcon -P "$rconPort" -p "$rconPassword" save-all stop >/dev/null 2>&1; then
    echo "服务端已关闭"
else
    echo "服务端已关闭或连接失败"
fi

if ! test -e "$targetDir"; then
    if mkdir -p "$targetDir"; then
        echo "${targetDir}目录创建成功"
    else
        echo "出错"
        exit 1
    fi
fi

latestNum=`ls "$targetDir"|sort|tail -n 1|sed -E 's/.*died([0-9]+)\.tar/\1/'`
if test -z $latestNum; then
    latestNum=1
fi
echo "latestNum: $latestNum"

sleep=1
while lsof "$serverJar" >/dev/null  2>&1;
do
    echo "${serverJar}还在运行,${sleep}秒后重试"
    sleep $sleep
    #sleep=$((10#$sleep+1))
done

path1="$targetDir/$prefix`printf '%03d' $((10#$latestNum+1))`.tar"

if test -e "$levelName"; then
    if tar -cf "$path1" "$levelName"; then
        rm -r "$levelName"
        echo "备份文件创建成功 \"$path1\" 大小:`ls -lh "$path1" | awk '{print $5}'`"
    else
        echo "备份文件创建失败"
        exit  1
    fi
else
    echo "存档目录不存在,将不会创建压缩文件"
fi

if ! screen -ls|grep -q "$screenName"; then
    screen -dmS "$screenName"
fi

if screen -S "$screenName" -X stuff "cd $serverRootDir;./r\n"; then
    echo "服务端启动中"
fi