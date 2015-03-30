#!/bin/bash

pvt_suppress_main="true"
source "$(dirname $0)/pvt.sh"

function pvt_test_show_modules_and_configs {
  printf "=====  test show modules and configs =====\n"
  for m in ${all_modules[*]}; do
    printf ${module_names[$m]}" : "  
	printf ${conf_files[$m]}"\n"
  done
  printf "\n"
}

function pvt_test_show_plugins {
 printf "=====  test show plugins  =====\n"
  for p in ${plugins[*]}; do
    printf ${module_names[$p]}"\n"  
  done
  printf "\n"
}

function pvt_test_show_plugin_dependents {
 printf "=====  test show plugin dependents  =====\n"
  for p in ${plugins[*]}; do
    printf ${module_names[p]}": "
    set_dependents $p
	for d in ${dependents[*]}; do
	  printf ${module_names[d]}"; "
	done
	printf "\n"
  done
  printf "\n"
}

function pvt_test_set_invalid_dependents_internal {
  printf "$1 plugin id\n"
  set_dependents $2
  printf "dependents size = "${#dependents[*]}"\n\n"
}

function pvt_test_set_invalid_dependents {
  printf "=====  test set invalid dependents  =====\n"
  pvt_test_set_invalid_dependents_internal "empty"
  pvt_test_set_invalid_dependents_internal "invalid integer (255)" 255
  pvt_test_set_invalid_dependents_internal "text" "abc"
  printf "\n"
}

function pvt_test_validate_version_internal {
  printf "version = '$1'"
  new_version="$1"
  validate_version
  local resolution="invalid"
  if [ $version_is_valid -eq 1 ] ; then
    resolution="valid"
  fi
  printf "is $resolution"
  if [[ $resolution != $2 ]] ; then
    printf " ERROR $2 EXPECTED"
  fi
  printf "\n"
}

function pvt_test_validate_version {
  printf "=====  test version pattern  =====\n"
  pvt_test_validate_version_internal "123.0" "valid"
  pvt_test_validate_version_internal "45.78" "valid"
  pvt_test_validate_version_internal "456.38.45" "valid"
  
  pvt_test_validate_version_internal "42" "invalid"
  pvt_test_validate_version_internal "12.23.34.45" "invalid"
  pvt_test_validate_version_internal "12.23." "invalid"
  pvt_test_validate_version_internal ".234" "invalid"
  pvt_test_validate_version_internal ".234." "invalid"
  pvt_test_validate_version_internal ".236.345." "invalid"
  pvt_test_validate_version_internal "19..28" "invalid"
  pvt_test_validate_version_internal "19.-28" "invalid"
  pvt_test_validate_version_internal "abc12" "invalid"
  pvt_test_validate_version_internal "a1.b2" "invalid"
  pvt_test_validate_version_internal "ab.bd.ce" "invalid"
  
  printf "two errors below expected\n"
  pvt_test_validate_version_internal "456.38.45" "invalid"
  pvt_test_validate_version_internal "42" "valid"
  printf "\n"
}


# list all tests here
pvt_test_show_modules_and_configs
pvt_test_show_plugins
pvt_test_show_plugin_dependents
pvt_test_set_invalid_dependents
pvt_test_validate_version 
