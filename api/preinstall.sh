#!/bin/sh
gem install bundler:$BUNDLER_VERSION
bundle _${BUNDLER_VERSION}_ install
