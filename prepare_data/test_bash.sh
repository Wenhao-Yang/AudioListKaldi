#!/usr/bin/env bash

loss=center

if [ $loss == "center" ] ; then
  loss_ratio=0.1
elif [ $loss == "coscenter" ] ;then
  loss_ratio=0.01
fi

echo $loss_ratio