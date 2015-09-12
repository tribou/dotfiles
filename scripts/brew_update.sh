#!/bin/bash

echo '##### Update local brew cache'
brew update

echo '##### List outdated packages'
brew outdated

echo '##### Upgrade outdated packages'
brew upgrade --all

