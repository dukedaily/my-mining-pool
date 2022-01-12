#!/bin/bash

cmd=/usr/local/bin/truffle-flattener
contracts=`ls contracts/implement/YouSwap*`
build_dir="build"

if [ -d "$build_dir" ]; then
	echo "rm -rf $build_dir"
	rm -rf $build_dir
fi

mkdir $build_dir

for i in $contracts; do 
	echo current: $i
	dst=${build_dir}/`basename $i`_flat.sol

	echo dst: $dst
	$cmd $i > $dst 2>/dev/null
done