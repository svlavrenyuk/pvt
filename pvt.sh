#!/bin/bash

source "$(dirname $0)/pvt_config.sh"

#################  functions  ######################

version_pattern="[0-9]\{1,\}\.[0-9]\{1,\}\(\.[0-9]\{1,\}\)\{0,1\}"

version_is_valid=-1
function validate_version {
  version_is_valid=0
  local resolution=$(echo "$new_version" | sed "s/$version_pattern/valid/")
  if [[ $resolution == "valid" ]] ; then
    version_is_valid=1
  fi
}

function update_version_number {
  local conf_file="$1"
  sed -i "s/$plugin_name:$version_pattern/$plugin_name:$new_version/" "$conf_file"
}

function generate_branch_name {
  branch_name="$base_branch_name-$plugin_name-$new_version"
}

###########  interaction helper functions  ###########

function gather_plugin_info {
  printf "\n"
  printf "select plugin\n"
  local min_option=1
  local max_option=${#plugins[*]}
  local option=$min_option
  local plugins_by_option=()
  
  for plugin_id in ${plugins[*]}; do
    printf "$option) ${module_names[$plugin_id]}\n"
    plugins_by_option[$option]=$plugin_id
    ((option++))
  done
  printf "> "
  read option
  if [[ !(($option -ge $min_option) && ($option -le $max_option)) ]]; then
    option=1
  fi
  plugin_id=${plugins_by_option[$option]}
  plugin_name=${module_names[$plugin_id]}  
  printf "$plugin_name selected\n"
  
  until [ $version_is_valid -eq 1 ] ; do
    printf "new version = "
    read new_version
	validate_version
	if [ $version_is_valid -eq 0 ] ; then
		printf "version is invalid. expected format MAJOR.MINOR[.MISC], e.g. 123.4 or 123.4.5\n"
	fi
  done
}

function gather_git_info {
  printf "\n"
  printf "commit to\n"
  printf "1) master\n"
  printf "2) new branch based on master\n"
  printf "3) existing branch\n"
  printf "4) new branch\n"
  printf "> "
  local option=-1
  read option

  case $option in
  2) 
    base_branch_name="master"
    generate_branch_name
    create_new_branch=1
  ;;
  3) 
    printf "branch = "
    read branch_name
    create_new_branch=0
  ;;
  4)  
    printf "base branch = "
    read base_branch_name
    generate_branch_name
    create_new_branch=1
  ;;
  *)
    branch_name="master"
    create_new_branch=0
  ;;
  esac

  printf "commit to $branch_name"
  if [ $create_new_branch -eq 1 ] ; then
    printf " based on $base_branch_name"
  fi
  printf "\n"
}

function acquire_confirmation {
  local confirmations=("!" "go" "ok" "yes" "run")
  local confirmations_length=${#confirmations[*]}
  local confirmation="A"
  local entered_confirmation="B"
  until [[ $entered_confirmation == $confirmation ]] ; do
    confirmation_random_index=$(expr $RANDOM % $confirmations_length)
    confirmation=${confirmations[$confirmation_random_index]}
	printf "\n"
	printf "to confirm enter '$confirmation'\n"
    read entered_confirmation
  done
}

###############  git related functions  ###############

function git_perist_state {
  # TODO git diff
  #number_of_status_lines=$(git status --branch --porcelain --untracked-files=no | sed -n $=)
  #if [ $number_of_status_lines -eq 1 ] ; then
  git update-index -q --ignore-submodules --refresh
  if ((git diff-files --quiet --ignore-submodules) && (git diff-index --cached --quiet --ignore-submodules HEAD --)) ; then
    stashed=0
	printf "working directory is clean.\n"
  else
    printf "uncommited changes detected.\n"
    git stash #--quiet
    stashed=1
	printf "uncommited changes stashed.\n"
  fi
  
  # get current branch
  prev_ref=$(git rev-parse --abbrev-ref HEAD)
  detached_state=0
  if [[ $prev_ref == "HEAD" ]] ; then
    # detached state, get commit hash
	prev_ref=$(git rev-parse HEAD)
	detached_state=1
  fi
  printf "currently on $prev_ref "
  if [ $detached_state -eq 0 ] ; then
    printf "branch.\n"
  else
    printf "commit in detached state.\n"
  fi
  
  if [ $create_new_branch -eq 1 ] ; then
	git branch $branch_name $base_branch_name #--quiet
	printf "branch $branch_name created.\n"
  fi
  
  if [[ $branch_name != $prev_ref ]] ; then
    git checkout $branch_name #--quiet
    printf "branch $branch_name checked out.\n"
  fi
}

function git_restore_state {
  if [[ $branch_name != $prev_ref ]] ; then
    git checkout $prev_ref #--quiet
    printf "$prev_ref checked out.\n"
  fi
  
  if [ $stashed -eq 1 ] ; then
    git stash apply #--quiet
	printf "uncommited changes unstashed.\n"
  fi
  
  cd "$start_dir"
}

function git_process {
  module_id=-1 
  module_name=""
  repo_path=""
  conf_file=""
  # prev_ref is git branch (or commit hash if detached) user was on when started this script
  prev_ref=""
  detached_state=-1
  # any uncommited changes?
  stashed=-1
  
  start_dir="$(pwd)"
  
  module_id=$1
  module_name="${module_names[module_id]}"
  repo_path="${git_repos[module_id]}"
  printf "\n"
  printf "processing $module_name\n"
  printf "git repo path is '$repo_path'\n"
  cd "$repo_path"
  if [ $? -ne 0 ] ; then
    printf "cd failed. skipping $module_name\n"
	cd "$start_dir"
	return 1
  fi
  
  conf_file="${conf_files[module_id]}"
  if [ ! -f "$conf_file" ] ; then
    printf "configuration file '$conf_file' not found. skipping $module_name\n"
	cd "$start_dir"
	return 1
  fi
  
  git_perist_state
  
  if [ $create_new_branch -eq 0 ] ; then
    # TODO improvement detect and handle diverged state if possible
    git pull origin $branch_name #--quiet
  fi  
  
  update_version_number "$conf_file"
  printf "config file updated.\n"
  git add --all #--quiet
  
  #number_of_status_lines=$(git status --branch --porcelain --untracked-files=no | sed -n $=)
  #if [ $number_of_status_lines -eq 1 ] ; then
  git update-index -q --ignore-submodules --refresh
  if (git diff-index --cached --quiet --ignore-submodules HEAD --)  ; then
    printf "nothing to commit. presumably plugin version is already updated.\n"
	git_restore_state
	return 0
  fi

  git commit -m "updated $plugin_name version to $new_version" --quiet
  printf "commited.\n"
  
  # TODO improvement detect failure and retry
  #git push origin $branch_name #--quiet
  #printf "pushed.\n"
    
  git_restore_state
}

##############  main  ###########################

function pvt_main {
  plugin_id=-1
  plugin_name=""
  new_version=""

  branch_name=""
  base_branch_name=""
  create_new_branch=-1

  printf "This script will help you to update plugin version in all dependent applications.\n"
  printf "Note: if invalid dialog option is chosen, it is replaced by the first available option.\n"
  
  gather_plugin_info
  gather_git_info
  
  set_dependents $plugin_id
  printf "\n"
  printf "affected applications\n"
  for dependent_module in ${dependents[*]} ; do    
    printf "${module_names[dependent_module]}\n"
  done
  
  acquire_confirmation
  
  for dependent_module in ${dependents[*]} ; do    
    git_process $dependent_module
  done
  
  # TODO improvement select affected modules - currently all dependent
}

###################################################

if [[ "$pvt_suppress_main" != "true" ]] ; then
  pvt_main
fi
