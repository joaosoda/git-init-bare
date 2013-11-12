#!/bin/bash

usage() {
  echo "Usage $0 [options] <project_name>
    OPTIONS:
      -h	Show help message
      -r	Repository directory (default: /var/www/git)
      -d	Deploy directory (e.g.: /var/www)
      -n	Repository User Name (default: apache)
      -g	Repository User Group (default: apache)
      -u	Repository URL (default: localhost/git)"
}

git_bare() {
  git init --bare $REPOPROJ
  cd $REPOPROJ
  sudo chown $USER:$GROUP $REPOPROJ -R
  git update-server-info
}

hook_edit() {
  echo "#!/bin/bash
unset GIT_DIR
GIT_TREE_WORK=$DEPLOY/$PROJ
cd \$GIT_TREE_WORK
echo \"===== DEPLOYING =====\"
git pull
echo \"===== FINISHED  =====\"" > $HOOK

  chmod +x $HOOK
}

git_clone() {
  git clone http://$URL/$PROJ.git $DEPLOY/$PROJ
  chown $USER:$GROUP $DEPLOY/$PROJ -R
  chmod +x $DEPLOY/$PROJ
}

for i in $@; do :; done #getting the last arg
PROJ=$i
REPO=/var/www/git
USER=apache
GROUP=apache
URL=localhost/git

while getopts "hr:d:n:g:u:" o; do
  case "${o}" in
    h)
      usage
      ;;
    r)
      REPO=${OPTARG}
      echo "Repository: $REPO"
      ;;
    d)
      DEPLOY=${OPTARG}
      echo "Deploy Directory: $DEPLOY"
      ;; 
    n)
      USER=${OPTARG}
      echo "User Name: $USER"
      ;;
    g)
      GROUP=${OPTARG}
      echo "User Group: $GROUP"
      ;;
    u)
      URL=${OPTARG}
      echo "URL: $URL"
      ;;
    *)
      usage
      ;;
  esac
done

REPOPROJ=$REPO/$PROJ.git
HOOK=$REPOPROJ/hooks/post-receive

if [ -z "${PROJ}" ]; then
	usage
	exit 1
fi

git_bare
hook_edit

if [ ! -z "${DEPLOY}" ]; then
  git_clone
fi
