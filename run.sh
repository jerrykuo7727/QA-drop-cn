#!/bin/bash

python3_cmd=python3

stage=2
use_gpu=cuda:1

model=xlnet  # (bert|xlnet)
model_path=/home/M10815022/Models/xlnet-base-chinese
save_path=./models/xlnet


if [ $stage -le 0 ]; then
  echo "==================================================="
  echo "     Convert traditional Chinese to simplified     "
  echo "==================================================="
  for name in drop_dataset_train_cn_azure.json drop_dataset_dev_cn_azure; do
    file=dataset/$name.json
    echo "Converting '$file'..."
    opencc -i $file -o $file -c t2s.json || exit 1
  done
  echo "Done."
fi


if [ $stage -le 1 ]; then
  echo "======================"
  echo "     Prepare data     "
  echo "======================"
  rm -rf data
  for split in train dev test; do
    for dir in passage passage_no_unk question question_no_unk answer span; do
      mkdir -p data/$split/$dir
    done
  done
  $python3_cmd scripts/prepare_${model}_drop_data.py $model_path || exit 1
  $python3_cmd scripts/prepare_${model}_fgc_data.py $model_path dev FGC_release_A_dev || exit 1
  $python3_cmd scripts/prepare_${model}_fgc_data.py $model_path test FGC_release_A_test || exit 1
fi


if [ $stage -le 2 ]; then
  echo "================================="
  echo "     Train and test QA model     "
  echo "================================="
  if [ -d $save_path ]; then
    echo "'$save_path' already exists! Please remove it and try again." #; exit 1
  fi
  mkdir -p $save_path
  $python3_cmd scripts/train_${model}.py $use_gpu $model_path $save_path
fi
