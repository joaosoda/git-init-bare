#!/bin/bash

usage() {
  echo "Usage $0 [options] <project_name>
    OPTIONS:
      -h	Show help message
      -r	Repository directory (default: /var/www/git)
      -d	Deploy directory (e.g.: /var/www)
      -n	Repository User Name (default: apache)
      -g	Repository User Group (default: apache)
      -u	Repository URL (default: localhost/git)
      -f	Configuration File"
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

##
# Configuration File
#
# Params
#   PROJ	Project Name
#   REPO	Repository Directory
#   DEPLOY	Deployment Directory
#   USER	User Name
#   GROUP	User Name
#   URL 	Clone URL
#
# EXAMPLE
#   PROJ=foobar
#   REPO=/var/repo
#   DEPLOY=/var/www/html
#   USER=www-data
#   GROUP=www-data
#   URL=user@git.host
##

get_config() {
  if [ -f $1 ]; then
    IFS="="
    while read -r key value; do
      case "${key}" in
        REPO)
	  REPO=$value
          ;;
        PROJ)
	  PROJ=$value
          ;;
        DEPLOY)
	  DEPLOY=$value
          ;;
        USER)
	  USER=$value
          ;;
        GROUP)
	  GROUP=$value
          ;;
        URL)
	  URL=$value
          ;;
      esac
    done < $1
  else
    echo "File $1 not exists."
    exit 1
  fi
}

for i in $@; do :; done #getting the last arg
PROJ=$i
REPO=/var/www/git
USER=apache
GROUP=apache
URL=localhost/git


while getopts "hr:d:n:g:u:f:" o; do
  case "${o}" in
    h)
      usage
      ;;
    r)
      REPO=${OPTARG}
      ;;
    d)
      DEPLOY=${OPTARG}
      ;; 
    n)
      USER=${OPTARG}
      ;;
    g)
      GROUP=${OPTARG}
      ;;
    u)
      URL=${OPTARG}
      ;;
    f)
      get_config ${OPTARG}
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

echo "Project Name: $PROJ"
echo "Repository: $REPO"
echo "Deploy Directory: $DEPLOY"
echo "User Name: $USER"
echo "Group Name: $GROUP"
echo "URL: $URL"

git_bare
hook_edit

if [ ! -z "${DEPLOY}" ]; then
  git_clone
fi
