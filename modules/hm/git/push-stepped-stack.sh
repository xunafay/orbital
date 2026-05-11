!f() {
    STACK=$(git stack);
    BASE=$(git merge-base-origin HEAD);
    PREV="";
    BOTTOM="";
    FIRST=1;
    while read BR; do
        if [ $FIRST -eq 1 ]; then
            TOP=$BR;
            FIRST=0;
            continue;
        fi;
        BELOW=$BR;
        BOTTOM=$BR;
        echo "=== $BELOW..$TOP ===";
        git rev-list --reverse $BELOW..$TOP |
        while read COMMIT; do
            MSG=$(git log -1 --pretty=format:'%s %h' $COMMIT);
            echo "$MSG";
            if [ -z "$DRY_RUN" ]; then
                git push --force-with-lease origin $COMMIT:$TOP || exit 1;
            fi;
        done;
        TOP=$BELOW;
    done <<< "$STACK";
    if [ -n "$BOTTOM" ]; then
    echo "=== $BASE..$BOTTOM ===";
    git rev-list --reverse $BASE..$BOTTOM |
    while read COMMIT; do
        MSG=$(git log -1 --pretty=format:'%s %h' $COMMIT);
        echo "$MSG";
        if [ -z "$DRY_RUN" ]; then
            git push --force-with-lease origin $COMMIT:$BOTTOM || exit 1;
        fi;
    done;
fi;
}; f
