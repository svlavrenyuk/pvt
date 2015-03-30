#!/bin/bash

pvt_test_clean_directory=1
pvt_test_detached=0

function git {
  case "$1" in
  "status")
    printf "branch info\n"
    if [ $pvt_test_clean_directory -eq 0 ] ; then
      printf "\n first change \n second change"
    fi
  ;;
  "rev-parse")
    if [[ "--abbrev-ref" == "$2" ]] ; then
      if [ $pvt_test_detached -eq 1 ] ; then
        printf "HEAD"
      else
	    printf "feature_branch"
	  fi
	else
	  printf "k3he83je0"
	fi
  ;;
  *)
    printf "git $1 mocked\n"
  ;;
  esac
}

source "$(dirname $0)/pvt.sh"
