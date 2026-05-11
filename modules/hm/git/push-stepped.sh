!f() {
    BRANCH=$(git rev-parse --abbrev-ref HEAD);
    MERGE_BASE=$(git merge-base-origin $BRANCH);
    git log $MERGE_BASE..HEAD --decorate-refs=refs/heads --pretty=format:"%h" --no-patch | tac | xargs -I {} git push --force-with-lease origin {}:$BRANCH;
};f
