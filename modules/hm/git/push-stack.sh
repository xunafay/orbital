!f() {
    BRANCH=${1-HEAD};
    git stack $BRANCH | xargs -I {} git push --force-with-lease origin {};
};f 
