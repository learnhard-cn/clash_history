#!/bin/bash

. ~/.bashrc

LOG() {
    echo "$(date +'%Y年%m月%d日%H:%M:%S'):" "$@"
}

# 更新新版本clash客户端可执行程序
update_clash_bin() {
    tmpfile="tmp.list"
    for fn in "premium" "release"
    do
        # Get latest binary download URL
        if [ "$fn" = "premium" ] ; then
            latest_url="https://github.com/Dreamacro/clash/releases/expanded_assets/premium"
            latest_version=`curl -L ${latest_url} | sed -n 's/.*clash-linux-armv7-\(.*\)\.gz.*/\1/p' |head -1`
        else
            url_302="https://github.com/Dreamacro/clash/releases/latest"
            latest_version=`curl -I ${url_302} | awk -F'/' '/^location/{ printf("%s",$NF) }'| sed 's/\r//g'`
            if [ "$latest_version" = "" ] ; then
                echo "Downloading latest version of clash error: cannot get latest version"
                return 1
            fi
            latest_url="https://github.com/Dreamacro/clash/releases/expanded_assets/${latest_version}"
        fi
        curl -L ${latest_url} | awk '/Dreamacro.clash.releases.download/ { gsub(/href=|["]/,""); print "https://github.com"$2 }' > ${tmpfile}
        # Check latest binary version
        cur_version=`cat ${fn}/version`
        LOG "$fn version check: cur_version:[$cur_version] , latest_version:[ $latest_version ]"
        if [ "${cur_version}" != "${latest_version}" ] ; then
            # 下载新版本
            for dn in `cat ${tmpfile}`
            do
                out_file=`basename ${dn}`
                latest_file=`echo ${out_file}|sed "s/${latest_version}/latest/g"`
                # 下载文件
                LOG "正在下载: [$out_file],url:${dn}."
                LOG "执行命令：wget -O ${out_file} -c ${dn}"
                
                wget -q -O ${out_file} -c ${dn}
                if [ "$?" = "0" ] ; then
                    # 下载成功
                    rm -f ${fn}/${latest_file}
                    echo "将[$out_file]文件存储为[${fn}/${latest_file}]"
                    mv ${out_file} ${fn}
                    cp ${fn}/${out_file}  ${fn}/${latest_file}
                else
                    LOG "download file[$out_file] failed!"
                fi
            done
            # 成功后，更新最新版本信息
            echo ${latest_version} > ${fn}/version
        fi
        rm ${tmpfile}
    done
}


update_clash_bin

