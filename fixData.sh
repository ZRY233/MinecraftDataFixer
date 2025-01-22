#!/bin/bash

if ! test -e "server.properties"; then
	echo "把我放在服务端根目录下,或第一次运行服务端"
	exit 1
fi
123
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
done
echo

echo "Archs也就是玩家获得的成就数,用来辨别新老数据的"
#输出一个表格
echo "Player Data Table:"
printf '%-3s\t%-36s\t%-5s\t%s\n' Num UUID Archs Name
for i in `seq 0 $(($userCount-1))`
do
	printf '%d\t%s\t%s\t%s\n' $(($i+1)) ${map["$i,uuid"]} ${map["$i,arch"]} ${map["$i,name"]}
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

	if test ${map["$(($src-1)),arch"]} -le ${map["$(($des-1)),arch"]}; then
		echo "被替换账户的成就数比替换账户多哦,你确定是正确的吗?"
	fi

	read -p "你确定要把 Num${src} 的数据替换到 Num${des} 上?(输入Yes继续,其他值重来)" con
	if test "$con" == "Yes"; then
		break
	fi
done

# playerdata stats advancements 


read -p "是否要备份原始文件?(输入Y备份,其他值不备份):" backup
if test "$backup" == "Y"; then
	if cp "$levelName/advancements/${map["$(($src-1)),uuid"]}.json" \
	"$levelName/advancements/${map["$(($src-1)),uuid"]}.json.backup"; then
    	echo "文件备份完成	$levelName/advancements/${map["$(($src-1)),uuid"]}.json.backup"
	fi

	if cp "$levelName/advancements/${map["$(($des-1)),uuid"]}.json" \
	"$levelName/advancements/${map["$(($des-1)),uuid"]}.json.backup"; then
	    echo "文件备份完成	$levelName/advancements/${map["$(($des-1)),uuid"]}.json.backup"
	fi

	if cp "$levelName/stats/${map["$(($src-1)),uuid"]}.json" \
	"$levelName/stats/${map["$(($src-1)),uuid"]}.json.backup"; then
	    echo "文件备份完成	$levelName/stats/${map["$(($src-1)),uuid"]}.json.backup"
	fi

	if cp "$levelName/stats/${map["$(($des-1)),uuid"]}.json" \
	"$levelName/stats/${map["$(($des-1)),uuid"]}.json.backup"; then
    	echo "文件备份完成	$levelName/stats/${map["$(($des-1)),uuid"]}.json.backup"
	fi

	if cp "$levelName/playerdata/${map["$(($src-1)),uuid"]}.dat" \
	"$levelName/playerdata/${map["$(($src-1)),uuid"]}.dat.backup"; then
    	echo "文件备份完成	$levelName/playerdata/${map["$(($src-1)),uuid"]}.dat.backup"
	fi

	if cp "$levelName/playerdata/${map["$(($des-1)),uuid"]}.dat" \
	"$levelName/playerdata/${map["$(($des-1)),uuid"]}.dat.backup"; then
    	echo "文件备份完成	$levelName/playerdata/${map["$(($des-1)),uuid"]}.dat.backup"
	fi

fi

echo -e "\n开始替换数据......\n"

if cp "$levelName/advancements/${map["$(($src-1)),uuid"]}.json" \
"$levelName/advancements/${map["$(($des-1)),uuid"]}.json"; then
	echo "文件替换完成	advancements"
fi

if cp "$levelName/stats/${map["$(($src-1)),uuid"]}.json" \
"$levelName/stats/${map["$(($des-1)),uuid"]}.json"; then
	echo "文件替换完成	stats"
fi

if cp "$levelName/playerdata/${map["$(($src-1)),uuid"]}.dat" \
"$levelName/playerdata/${map["$(($des-1)),uuid"]}.dat"; then
	echo "文件替换完成	playerdata"
fi

