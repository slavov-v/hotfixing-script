MASTER_BRANCH_NAME="master"
PRODUCTION_BRANCH_NAME="production"
DUMMY_BRANCH_NAME="hotfix/cleanup/dummy"

echo "Starting post-hotfix cleanup"

git checkout -b $DUMMY_BRANCH_NAME
echo "Cleaning $MASTER_BRANCH_NAME"
git branch -D $MASTER_BRANCH_NAME --quiet
echo "Cleaning $PRODUCTION_BRANCH_NAME"
git branch -D $PRODUCTION_BRANCH_NAME --quiet
git fetch origin --quiet
git checkout $MASTER_BRANCH_NAME --quiet
git branch -D $DUMMY_BRANCH_NAME --quiet

echo "Done. You are now on branch $MASTER_BRANCH_NAME"
