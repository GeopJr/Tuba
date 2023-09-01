#!/bin/bash

if [ $(basename "$PWD") = "po" ]; then
    cd ..
fi


find ./ -type f -name "*.in" | sort > po/POTFILES
echo "" >> po/POTFILES
find ./ -type f -name "*.ui" -exec grep -l "translatable=\"yes\"" {} \; | sort >> po/POTFILES
echo "" >> po/POTFILES
find ./ -type f -name "*.vala" -exec grep -l "_(\"" {} \; | sort >> po/POTFILES
