#!/usr/bin/env bash
# vim: set autoindent smartindent ts=4 sw=4 sts=4 noet filetype=sh:
[[ -t 1 ]] && { cG="\e[1;32m"; cR="\e[1;31m"; cB="\e[1;34m"; cW="\e[1;37m"; cY="\e[1;33m"; cG_="\e[0;32m"; cR_="\e[0;31m"; cB_="\e[0;34m"; cW_="\e[0;37m"; cY_="\e[0;33m"; cZ="\e[0m"; export cR cG cB cY cW cR_ cG_ cB_ cY_ cW_ cZ; }
TOOLS_NEEDED="awk git readlink"
for tool in $TOOLS_NEEDED; do type $tool > /dev/null 2>&1 || { echo -e "${cR}ERROR:${cZ} couldn't find '$tool' which is required by this script."; exit 1; }; done
pushd $(dirname $0) > /dev/null; CURRABSPATH=$(readlink -nf "$(pwd)"); popd > /dev/null; # Get the directory in which the script resides

# Walk through the submodules from .gitmodules
git -C "$CURRABSPATH" config --file "$CURRABSPATH/.gitmodules" --name-only --get-regexp path|while read modpathkey; do
	submodkey="${modpathkey%.path}"
	modurlkey="$submodkey.url"
	modname="${submodkey#submodule.}"
	modpath=$(git -C "$CURRABSPATH" config --file "$CURRABSPATH/.gitmodules" "$modpathkey")
	modurl=$(git -C "$CURRABSPATH" config --file "$CURRABSPATH/.gitmodules" "$modurlkey")
	# Sanity check to assert our assumption about structure
	[[ "${modurl%%/*}" == ".." ]] || { echo -e "${cY}WARNING:${cZ} URL for origin of ${cW}${modname}${cZ} is not in a parent directory from here. ${cY}Skipping.${cZ}"; continue; }
	echo -e "${cG}${modname^^}${cZ}"
	echo -e "  ${cW}path${cZ} == ${cW}$modpath${cZ}"
	modabsurl="$(readlink -nf "$CURRABSPATH/$modurl")"
	echo -e "  ${cW}url${cZ}  == ${cW}$modurl${cZ} == $modabsurl"
	rmt_originurl=$(git "--git-dir=$modabsurl" remote get-url origin)
	echo -e "    ${cG}$modurl:${cZ} ${cW}origin${cZ}   == ${cW}$rmt_originurl${cZ}"
	rmt_upstreamurl=$(git "--git-dir=$modabsurl" remote get-url upstream 2> /dev/null || echo -n "")
	if [[ -n "$rmt_upstreamurl" ]]; then
		echo -e "    ${cG}$modurl:${cZ} ${cW}upstream${cZ} == ${cW}$rmt_upstreamurl${cZ}"
	else
		echo -e "    ${cG}$modurl:${cZ} ${cW}upstream${cZ} ... ${cY}does not exist!${cZ}"
	fi
	clonepath="${modurl%.git}"
	cloneabspath="${modabsurl%.git}"
	if [[ -d "$cloneabspath" ]]; then
		clone_originurl=$(git -C "$cloneabspath" remote get-url origin)
		echo -e "      ${cG}$clonepath:${cZ} ${cW}origin${cZ} == ${cW}$clone_originurl${cZ}"
		echo -e "        ${cY_}$(git -C "$cloneabspath" log --oneline -n 1 --pretty=format:"%H")${cZ} ${cY}$(git -C "$cloneabspath" log --oneline -n 1 --pretty=format:"%d")${cZ}"
		echo -e "        ${cW}$(git -C "$cloneabspath" log --oneline -n 1 --pretty=format:"%an")${cZ} $(git -C "$cloneabspath" log --oneline -n 1 --pretty=format:"%ae")"
		echo -e "        ${cW}$(git -C "$cloneabspath" log --oneline -n 1 --pretty=format:"[%ai]")${cZ} $(git -C "$cloneabspath" log --oneline -n 1 --pretty=format:"%s")"
	else
		echo -e "      ${cG}$clonepath:${cZ} ... ${cR}DOES NOT EXIST!${cZ}"
	fi
done
