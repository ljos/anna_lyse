#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

function usage() {
    NAME="$(basename $0)"
    cat <<EOF
${NAME}

Usage:
  ${NAME} [-b|-n] [-s] FILE
  ${NAME} -h | --help

Options:
  -h --help --hjelp   Show this screen.
  -b --nob --bokmål   Tag bokmål (The default).
  -n --nno --nynorsk  Tag nynorsk.
EOF
}

LANG="nob"
while [[ "$#" > 0 ]]; do
    KEY="$1"
    case ${KEY} in
	-b|--nob|--bokmål|--bokmal)
	    LANG="nob"
	    ;;
	-n|--nno|--nynorsk)
	    LANG="nno"
	    ;;
	-h|--help)
	    usage
	    exit 0
	    ;;
	* )
	    FILE="$1"
    esac
    shift
done

CURDIR=$(realpath "${0}")
CURDIR=$(dirname "${CURDIR}")

PARSER_EVAL="${CURDIR}../bin/parser_eval"
CONTEXT="${CURDIR}/../res/${LANG}_context.pbtxt"
MODEL_DIR="${CURDIR}/../models/${LANG}/tagger-params"

cat "${FILE:-/dev/stdin}"				\
    | "${PARSER_EVAL}" --input="stdin-conll"		\
		       --output=stdout-conll		\
		       --hidden_layer_sizes=64		\
		       --arg_prefix=brain_tagger	\
		       --graph_builder=structured	\
		       --task_context="${CONTEXT}"	\
		       --model_path="${MODEL_DIR}"	\
		       --slim_model			\
		       --batch_size=1024		\
		       --alsologtostderr
