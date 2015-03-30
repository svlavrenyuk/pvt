#!/bin/bash

################  modules  ################

INV=10
USR=20
BKS=30
PUR=40
API=50
BOX=60
inv_marshall=70
inv_api=80
bks_domain=90
usr_domain=100

all_modules=($INV $USR $BKS $PUR $API $BOX $inv_marshall $inv_api $bks_domain $usr_domain)

plugins=($inv_marshall $inv_api $bks_domain $usr_domain)

dependents=()
function set_dependents {
  case $1 in
  $inv_marshall)
    dependents=($INV $USR $BKS $PUR $API $BOX)
	# $inv_api is also dependent, but it's supposed to be updated manually prior to using this script 
  ;;
  $inv_api)
    dependents=($USR $BKS $PUR $API $BOX)
  ;;
  $bks_domain)
    dependents=($USR $BKS $PUR $API)
  ;;
  $usr_domain)
    dependents=($USR $BKS $API)
  ;;
  *)
    dependents=()
    printf "ERROR: script bug detected. invalid plugin id = $1\n"    
  ;;
  esac
}


###############  module names  ###################

module_names[$INV]="INV/inventory"
module_names[$USR]="USR/account"
module_names[$BKS]="BKS/backstage"
module_names[$PUR]="PUR/purchase"
module_names[$API]="API/api"
module_names[$BOX]="BOX/boxoffice"
module_names[$inv_marshall]="tfly-inventory-marshall-domain"
module_names[$inv_api]="tfly-inventory-api"
module_names[$bks_domain]="tfly-backstage-domain"
module_names[$usr_domain]="tfly-user-account-domain"

############  git repo and config files pathes  ##############

# absolute pathes required!
path_start="$HOME/projects/ticketfly/"
path_end="/grails-app/conf/BuildConfig.groovy"

for module_id in ${all_modules[*]}; do
  git_repos[$module_id]="$path_start${module_names[$module_id]}"
  conf_files[$module_id]="${git_repos[$module_id]}$path_end"
done
