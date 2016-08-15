#!/usr/bin/env bash
#
# Copyright (C) 2016  Bjarte Johansen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -o errexit
set -o nounset
set -o pipefail

# Get the source directory of the script.
CURDIR=$(realpath "${0}")
CURDIR=$(dirname "${CURDIR}")

TRAINER="${CURDIR}/../bin/parser_trainer"
export TRAINER

CONTEXT="${1}"
export CONTEXT

MODEL_FOLDER="${CURDIR}/../models/$(basename \"${CONTEXT}\")"

function alyse_train {
    local SEED=$(shuf -i 0-10000 -n 1)
    local LAYER_SIZES=$(bc -l <<< "$1^7")
    local LEARNING_RATE=$(bc <<< "$2*0.01")
    local DECAY_STEPS=16502
    local MOMENTUM=$(bc <<< "$3*0.1")
    local PARAMS="${LAYER_SIZES}-${LEARNING_RATE}-${DECAY_STEPS}-${MOMENTUM}-$SEED"
    ${TRAINER} --task_context="${CONTEXT}"		\
    	       --arg_prefix=brain_pos			\
    	       --compute_lexicon			\
    	       --graph_builder=greedy			\
    	       --training_corpus=training-corpus	\
    	       --tuning_corpus=tuning-corpus		\
    	       --output_path="${MODEL_FOLDER}"		\
    	       --batch_size=32				\
    	       --hidden_layer_sizes="${LAYER_SIZES}"	\
    	       --learning_rate="${LEARNING_RATE}"	\
    	       --decay_steps="${DECAY_STEPS}"		\
    	       --momentum="${MOMENTUM}"			\
    	       --seed="${SEED}"				\
    	       --params="${PARAMS}"
}
export -f alyse_train

parallel --env train				\
	 --env CONTEXT				\
	 --env TRAINER				\
	 --plain				\
	 --jobs 3				\
	 --tag					\
         --line-buffer				\
	 --timeout 28800			\
	 'alyse_train {1} {2} {3}'		\
	 ::: {1..9}				\
	 ::: {5..15}				\
	 ::: {5..15}
