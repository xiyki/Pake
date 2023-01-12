#!/bin/bash

if [ ! -d "node_modules" ]; then
    npm i
fi


if [ ! -d "output" ]; then
    mkdir output
fi

if [[ "$OSTYPE" =~ ^linux ]]; then
    if [ ! -d "output/linux" ]; then
        mkdir output/linux
    fi
fi


if [[ "$OSTYPE" =~ ^darwin ]]; then
    if [ ! -d "output/macos" ]; then
        mkdir output/macos
    fi
fi

SHELL_FOLDER=$(cd "$(dirname "$0")" || exit 1; pwd)
# total app number, ignore first line
total=$(sed -n '$=' app.csv)
export total=$((total-1))
export index=1

export old_name="weread"
export old_title="WeRead"
export old_zh_name="微信阅读"
export old_url="https://weread.qq.com/"
export package_prefix="com-tw93"



if [[ "$OSTYPE" =~ ^linux ]]; then
    echo "==============="
    echo "Build for Linux"
    echo "==============="
    export sd=${SHELL_FOLDER}/sd-linux-x64
    chmod +x "$sd"
    # for linux, package name may be com.xxx.xxx
    echo "rename package name"
    export desktop_file="src-tauri/assets/${package_prefix}.weread.desktop"
    $sd "\"productName\": \"WeRead\"" "\"productName\": \"${package_prefix}-weread\"" src-tauri/tauri.conf.json
fi

if [[ "$OSTYPE" =~ ^darwin ]]; then
    echo "==============="
    echo "Build for MacOS"
    echo "==============="

    export sd=${SHELL_FOLDER}/sd-apple-x64
    chmod +x "$sd"
    echo "rename package name"
    $sd "\"productName\": \"weread\"" "\"productName\": \"WeRead\"" src-tauri/tauri.conf.json
fi

tail -n +2 app.csv | while IFS=, read -r -a arr;
do
    package_name=${arr[0]}
    package_title=${arr[1]}
    package_zh_name=${arr[2]}
    url=${arr[3]}
    # replace package info
    $sd -s "${old_url}" "${url}" src-tauri/tauri.conf.json
    $sd "${old_name}" "${package_name}" src-tauri/tauri.conf.json
    # echo "update ico with 32x32 pictue"
    # $sd "${old_name}" "${package_name}" src-tauri/src/main.rs

    # for apple, need replace title
    if [[ "$OSTYPE" =~ ^darwin ]]; then
        # update icon
        # if icon exsits, change icon path
        if [ ! -f "src-tauri/icons/${package_name}.icons" ]; then
            # else, replace icon to default
            echo "warning"
            echo "icon for MacOS not exsist, will use default icon to replace it"
            echo "warning"
            cp "src-tauri/icons/icon.icns" "src-tauri/icons/${package_name}.icons"
        fi
        $sd "${old_name}" "${package_name}" src-tauri/tauri.macos.conf.json
        $sd "${old_title}" "${package_title}" src-tauri/tauri.conf.json
    fi

    # echo "update ico with 32x32 pictue"
    # cp "src-tauri/png/${package_name}_32.ico" "src-tauri/icons/icon.ico"

    if [[ "$OSTYPE" =~ ^linux ]]; then
        # update icon
        # if icon exsits, change icon path
        if [ ! -f "src-tauri/png/${package_name}_512.png" ]; then
            # else, replace icon to default
            echo "warning"
            echo "icon for linux not exsist, will use default icon to replace it"
            echo "warning"
            cp "src-tauri/png/icon_256.ico" "src-tauri/png/${package_name}_256.ico"
            cp "src-tauri/png/icon_512.png" "src-tauri/png/${package_name}_512.png"
        fi
        $sd "${old_name}" "${package_name}" src-tauri/tauri.linux.conf.json
        echo "update desktop"
        old_desktop="src-tauri/assets/${package_prefix}-${old_name}.desktop"
        new_desktop="src-tauri/assets/${package_prefix}-${package_name}.desktop"
        mv "${old_desktop}" "${new_desktop}"
        $sd "${old_zh_name}" "${package_zh_name}" "${new_desktop}"
        $sd "${old_name}" "${package_name}" "${new_desktop}"
    fi

    # update package info
    old_name=${package_name}
    old_title=${package_title}
    old_zh_name=${package_zh_name}
    old_url=${url}

    echo "building package ${index}/${total}"
    echo "package name is ${package_name} (${package_zh_name})"

    if [[ "$OSTYPE" =~ ^linux ]]; then
        npm run tauri build
        mv src-tauri/target/release/bundle/deb/${package_prefix}-${package_name}*.deb output/linux/${package_title}_amd64.deb
        mv src-tauri/target/release/bundle/appimage/${package_prefix}-${package_name}*.AppImage output/linux/${package_title}_amd64.AppImage
        echo clear cache
        rm src-tauri/target/release
        rm -rf src-tauri/target/release/bundle

    fi

    if [[ "$OSTYPE" =~ ^darwin ]]; then

        npm run tauri build -- --target universal-apple-darwin
        mv src-tauri/target/universal-apple-darwin/release/bundle/dmg/*.dmg output/macos/${package_title}.dmg
        echo clear cache
        rm -rf src-tauri/target/universal-apple-darwin
        rm src-tauri/target/aarch64-apple-darwin/release
        rm src-tauri/target/x86_64-apple-darwin/release
    fi

    echo "package build success!"
    index=$((index+1))
done

echo "build all package success!"
echo "you run 'rm src-tauri/assets/*.desktop && git checkout src-tauri' to recovery code"
