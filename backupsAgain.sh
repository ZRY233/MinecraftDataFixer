#!/bin/bash

#logs/latest.log 文件会实时更新控制台输出

#todo:多op支持
op="ZRY233"

#todo:这里不能这么写
echo "" > logs/old.log
while true;
do

    while true;
    do
        diff=`diff --new-line-format="%L" \
            --unchanged-line-format="" \
            --old-line-format="" \
            logs/old.log logs/latest.log \
            |grep "<$op> ;;"`
        echo "diff: $diff"

        if test "`echo "$diff"|awk -F"<$op> ;;" '{print $2}'`" == ""; then
            echo "命令部分为空"
            break
        fi
        
        while IFS= read -r line;do
            if test `echo "$line"|awk -F"<$op> ;;" '{print $1}'|grep -o '<[^>]*>'`; then
                echo "not ops"
                continue
            else
                echo "is op"
            fi

            command=`echo "$line"|awk -F"<$op> ;;" '{print $2}'`
            case "$command" in #todo:调用函数完成
                "backup")
                    echo "backup"
                    ;;
                "add")
                    echo "add"
                    ;;
                "del")
                    echo "del"
                    ;;
                "test")
                    echo "test"
                    mcrcon -p password "say yes"
                    ;;
                *)
                    echo "qqqq"
                    ;;
            esac
        done <<< "$diff"
        break
    done
    cp logs/latest.log logs/old.log
    sleep 10
done