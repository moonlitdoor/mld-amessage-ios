#!/bin/sh

git=$(sh /etc/profile; which git)

stringIndex() {
    x="${1%%$2*}"
    [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

stringLastIndex() {
    echo "$1" | awk -F"$2" '{print length($0)-length($NF)}'
}

setIsSnapshot () {
    output=$("$git" status --porcelain)
    if [ ! -z "$output" ]; then
        if [[ $1 == *"-g"* ]]; then
            withOutHash=$(echo $1 | cut -c1-$(stringIndex "$gitTag" "-g"))
            withOutCommitCount=$(echo $withOutHash | cut -c1-"$(($(stringLastIndex $withOutHash '-')))")
            commitCount=$(echo $withOutHash | cut -c"$(($(stringLastIndex $withOutHash '-') + 1))")
            echo "$withOutCommitCount$((commitCount + 1))-SNAPSHOT"
        else
            echo "$1-1-SNAPSHOT"
        fi
    else
        echo $1
    fi
}

gitTag=$("$git" describe --tags)
gitTagWithStatus="$(setIsSnapshot $gitTag)"
gitCommitAndTagCount="$(($($git rev-list HEAD --count) + $($git tag | wc -l)))"

dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"
target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"

for plist in "$target_plist" "$dsym_plist"; do
    if [ -f "$plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $gitCommitAndTagCount" "$plist"
        echo "Build number set to $gitCommitAndTagCount in ${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $gitTagWithStatus" "$plist"
        echo "Build version set to $gitTagWithStatus in ${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
    fi
done
