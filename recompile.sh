#!/bin/bash
cmd="rm -rf bin artifacts typechain cache&&npm run compile"
echo $cmd

rm -rf typechain cache artifacts bin
npm run compile