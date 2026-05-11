!f() {
    BRANCH=${1-HEAD};
    MERGE_BASE=$(git merge-base-origin $BRANCH);
    git log --decorate-refs=refs/heads --simplify-by-decoration --pretty=format:"%(decorate:prefix=,suffix=,tag=,separator=%n)" $MERGE_BASE..$BRANCH;
};f
