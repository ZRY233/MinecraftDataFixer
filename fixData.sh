#!/bin/bash

#本脚本用来快速修复因UUID不一致导致的玩家数据错误问题
#https://github.com/ZRY233/MinecraftDataFixer

if test "$1" == ""; then
	echo "第一个参数指定脚本运行目录"
	if ! test -e "server.properties"; then
		echo "没有找到server.properties文件,把我放在服务端根目录下,或第一次运行服务端"
		exit 1
	fi
elif test -e "$1"; then
	echo "切换运行目录至$1"
	cd "$1"
else
	echo "${1}目录不存在"
	exit 1
fi

#获取存档目录名
levelName=`cat server.properties|grep level-name|awk -F'=' '{print $2}'`
echo "levelName: $levelName"
if ! test -e "$levelName"; then
	echo "当前目录下没有找到存档目录哦"
	exit 1
fi

declare -A map	#这是一个map而不是list

userCount=`jq 'length' usercache.json`
echo "usersCount: $userCount"

for i in `seq 0 $(($userCount-1))`
do
	map["$i,uuid"]=`jq -r ".[$i].uuid" usercache.json`
	map["$i,name"]=`jq -r ".[$i].name" usercache.json`
	map["$i,arch"]=`jq -r 'length' "$levelName/advancements/${map["$i,uuid"]}.json"`
	map["$i,stat"]=`jq -r '.stats|map_values(length)|add' "$levelName/stats/${map["$i,uuid"]}.json"`

	if test -z ${map["$i,arch"]}; then
		echo "${map["$i,uuid"]}.json打开失败,Archs数据被重置为-1"
		map["$i,arch"]=-1
	fi

	if test -z ${map["$i,stat"]}; then
	echo "${map["$i,uuid"]}.json打开失败,Stats数据被重置为-1"
	map["$i,stat"]=-1
	fi
done
echo

echo "Archs也就是玩家获得的成就及配方数,用来辨别新老数据的"
echo "Stats也就是玩家拥有的统计信息条数,用处同上"
#输出一个表格
echo "Player Data Table:"
printf '%-3s\t%-36s\t%-5s\t%-5s\t%s\n' Num UUID Archs Stats Name
for i in `seq 0 $(($userCount-1))`
do
	printf '%d\t%s\t%s\t%s\t%s\n' $(($i+1)) ${map["$i,uuid"]} ${map["$i,arch"]} ${map["$i,stat"]} ${map["$i,name"]}
done
if test $userCount -eq 1; then
	echo "哥们,只有一个账户"
	exit 6
fi
echo

while true
do
	read -p "替换账户+空格+被替换账户,然后按下回车(输入Num即可):" src des
	if test $src -le $userCount && test $des -le $userCount &&! test $src -eq $des; then
		echo "contine"
	else
		echo "输入有效的数字"
		continue
	fi

	if test ${map["$(($src-1)),arch"]} -lt ${map["$(($des-1)),arch"]}; then
		echo "被替换账户的成就和配方数比替换账户多哦,你确定是正确的吗?"
	fi
	if test ${map["$(($src-1)),stat"]} -lt ${map["$(($des-1)),stat"]}; then
		echo "被替换账户的统计数据数比替换账户多哦,你确定是正确的吗?"
	fi

	read -p "你确定要把 Num${src} 的数据替换到 Num${des} 上?(输入Yes继续,其他值重来)" con
	if test "$con" == "Yes"; then
		break
	fi
done

# playerdata stats advancements 

read -p "是否要备份原始文件?(输入N不备份):" backup
if ! test "$backup" == "N"; then
	for dir in 'playerdata' 'stats' 'advancements';
	do
		for sd in $src $des;
		do
			fileName=`ls "$levelName/$dir"|grep "${map["$(($sd-1)),uuid"]}"|sort|head -n 1`
			if cp "$levelName/$dir/$fileName" "$levelName/$dir/$fileName.backup"; then
				echo "文件备份完成	$fileName.backup"
			fi
		done
	done
fi

echo -e "\n开始替换数据......\n"

for dir in 'playerdata' 'stats' 'advancements';
do
	fileNameSrc=`ls "$levelName/$dir"|grep "${map["$(($src-1)),uuid"]}"|sort|head -n 1`
	fileNameDes=`ls "$levelName/$dir"|grep "${map["$(($des-1)),uuid"]}"|sort|head -n 1`
	if cp "$levelName/$dir/${fileNameSrc}" "$levelName/$dir/${fileNameDes}"; then
		echo "文件替换完成	$dir"
	fi
done