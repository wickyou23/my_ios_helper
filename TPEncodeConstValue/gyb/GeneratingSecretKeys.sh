#!/bin/sh
export GMS_STAGING_API_KEY="<Add Const Value Here>"
export GMS_US_PRODUCTION_API_KEY="<Add Const Value Here>"
python3 gyb --line-directive '' -o "Secrets.swift" "Secrets.swift.gyb"
