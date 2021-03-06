exit_on_err () {
    if [ $1 != 0 ]
    then
	echo "Error encountered when: $2"

	exit 1
    fi
}

MASTER_BRANCH_NAME="master"
PRODUCTION_BRANCH_NAME="production"
YES="y"
NO="n"

current_branch=`git branch | grep \* | cut -d ' ' -f2`
parent=$1

if [ -z $1 ]
then
    echo "Provide the parent branch name"
    exit 1
fi

if [ "$current_branch" = "$MASTER_BRANCH_NAME" ] || [ "$current_branch" = "$PRODUCTION_BRANCH_NAME" ]
then
    echo "Branch must not be $MASTER_BRANCH_NAME or $PRODUCTION_BRANCH_NAME"

    exit 1
fi


if [ "$parent" != "$MASTER_BRANCH_NAME" ] && [ "$parent" != "$PRODUCTION_BRANCH_NAME" ]
then
    echo "Parent branch must be $MASTER_BRANCH_NAME or $PRODUCTION_BRANCH_NAME"

    exit 1
fi

master_new_branch_name="hotfix/m/$current_branch"
production_new_branch_name="hotfix/p/$current_branch"

echo "Creating hotfix from ${current_branch}"

m_new_branch_exists=false
p_new_branch_exists=false

m_new_branch=`git show-ref refs/heads/$master_new_branch_name`

if [ "$m_new_branch" ]
then
    echo "Branch $master_new_branch_name already exists.\nShould this branch be deleted (A new branch will be created automatically) ? y/n: "
    read answer

    if [ "$answer" = "$NO" ]
    then
	echo "Process canceled"

	exit 1
    fi

    m_new_branch_exists=true
fi

p_new_branch=`git show-ref refs/heads/$production_new_branch_name`

if [ "$p_new_branch" ]
then
    echo "Branch $production_new_branch_name already exists.\nShould this branch be deleted (A new branch will be created automatically) ? y/n: "
    read answer

    if [ "$answer" = "$NO" ]
    then
	echo "Process canceled"

	exit 1
    fi

    p_new_branch_exists=true
fi

if [ "$m_new_branch_exists" = true ]
then
    git branch -D $master_new_branch_name
fi

if [ "$p_new_branch_exists" = true ]
then
    git branch -D $production_new_branch_name
fi

if [ "$parent" = "$MASTER_BRANCH_NAME" ]
then
    first_branch=$master_new_branch_name
    second_branch=$production_new_branch_name
    first_base=$MASTER_BRANCH_NAME
    second_base=$PRODUCTION_BRANCH_NAME
    first_title="Master"
    second_title="Production"
else
    second_branch=$master_new_branch_name
    first_branch=$production_new_branch_name
    second_base=$MASTER_BRANCH_NAME
    first_base=$PRODUCTION_BRANCH_NAME
    second_title="Master"
    first_title="Production"
fi

parent_commit=`git show-ref $parent --heads --hash`
last_commit=`git rev-parse HEAD`

echo "Enter a title (will be modified with hotfix prefixes): "
read pr_title

create_pr () {
    base=$1
    branch=$2
    base_title=$3

    git checkout $base --quiet
    exit_on_err $? "checking out to to $base"
    git checkout -b $branch --quiet
    exit_on_err $? "checking out to $branch"
    git cherry-pick $parent_commit..$last_commit
    exit_on_err $? "cherry-picking commits"
    echo "Pushing to origin"
    git push origin $branch --quiet
    exit_on_err $? "pushing to origin $branch"
    echo "Creating PR to $base"
    hub pull-request -b $base -m "[HOTFIX: \`$base_title\`] $pr_title"
    exit_on_err $? "Creating a pull request towards $base"
}

create_pr $first_base $first_branch $first_title
create_pr $second_base $second_branch $second_title

echo "Cleaning up"

git checkout $current_branch --quiet
git branch -D $first_branch --quiet
git branch -D $second_branch --quiet

echo "Done"
