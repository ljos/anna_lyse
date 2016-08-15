# Build script for anna_lyse
#
# Copyright (C) 2016 Bjarte Johansen
#
# Users are granted the rights to distribute and use this software as
# governed by the terms of the GPLv3 License.

APP_NAME = anna_lyse
VERSION  = 0.0.1

OS := $(shell uname)

NDT         = res/20140328_NDT_1-01.tar.gz
NDT_SHA1SUM = "97935c225f98119aa94d53f37aa64762cba332f3 $(NDT)"
CONLL       = res/ndt_1-0_nob.conll res/ndt_1-0_nno.conll
SYNTAXNET   = bin/parser_eval bin/parser_trainer

NOB_DATA = res/ndt_1-0_nob.train.conll		\
	   res/ndt_1-0_nob.test.conll		\
	   res/ndt_1-0_nob.verify.conll

NNO_DATA = res/ndt_1-0_nno.train.conll		\
	   res/ndt_1-0_nno.test.conll		\
	   res/ndt_1-0_nno.verify.conll

all: data $(SYNTAXNET) $(APP_NAME)

$(APP_NAME): | bin
	ln --symbolic "$(CURDIR)/src/anna_lyse.sh" "$@"

train: data $(filter-out train, $(MAKECMDGOALS))

nob: | models
	bash aux/pos_train.sh models/nob_context.pbtxt 2>&1 | tee nob_alyse.log
nno: | models
	bash aux/pos_train.sh models/nno_context.pbtxt 2>&1 | tee nno_alyse.log

models:
	mkdir -p models

data: $(NOB_DATA) $(NNO_DATA)

%.train.conll %.test.conll %.verify.conll: %.conll
	python3 aux/conllshuf.py $<

$(CONLL): $(NDT)
	tar -Oxvf $(NDT) NDT_1-01/$(@F) > $@

$(NDT):
	curl http://www.nb.no/sbfil/tekst/$(@F) > $@
	echo $(NDT_SHA1SUM) | sha1sum -c -

bin/parser_eval: lib/models/syntaxnet/bazel-bin/syntaxnet/parser_eval | bin
	ln --symbolic "$(CURDIR)/$<" "$@"
bin/parser_trainer: lib/models/syntaxnet/bazel-bin/syntaxnet/parser_trainer | bin
	ln --symbolic "$(CURDIR)/$<" "$@"

bin:
	mkdir -p bin

lib/models/syntaxnet/bazel-bin/syntaxnet/parser_eval: syntaxnet
lib/models/syntaxnet/bazel-bin/syntaxnet/parser_trainer: syntaxnet

syntaxnet: lib
	export PYTHON_BIN_PATH="$(shell which python2.7)";	\
	export TF_NEED_GCP=0;					\
	export TF_NEED_CUDA=0;					\
	cd lib/models/syntaxnet/tensorflow;			\
	git apply "$(CURDIR)/aux/change_repo_gmock.patch";	\
	 ./configure
ifeq ($(OS), Darwin)
	cd lib/models/syntaxnet;				\
	bazel test --linkopt=-headerpad_max_install_names	\
		   syntaxnet/...				\
		   util/utf8/...
else
	cd lib/models/syntaxnet;				\
	bazel test syntaxnet/... util/utf8/...
endif

lib:
	git submodule update --init --recursive

clean:
	-rm -rf $(CONLL) $(NOB_DATA) $(NNO_DATA)
	-rm -rf bin
	cd lib/models/syntaxnet/tensorflow;		\
	git checkout -- tensorflow/workspace.bzl

clean_syntaxnet:
	cd lib/models/syntaxnet; bazel clean

.PHONY: all lib clean data syntaxnet
.INTERMEDIATE: $(NDT)
