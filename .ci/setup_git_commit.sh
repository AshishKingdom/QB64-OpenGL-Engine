#!/bin/bash

git config --local user.email "ashishkushwahacb@gmail.com"
git config --local user.name "auto-generate"
git add engine_method_noerror.bas
if [[ $(git diff --cached | wc -l) -gt 0 ]]
    then git commit -m "Update engine_method_noerror.bas"
fi
