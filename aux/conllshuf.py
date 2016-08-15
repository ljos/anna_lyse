#!/usr/bin/env python3
"""
conllshuf.py

Usage:
  conllshuf.py CONLLFILE...

Options:
  -h, --help               Print usage and exit


"""
from docopt import docopt
from random import shuffle
from os.path import splitext

if __name__ == '__main__':
    opts = docopt(__doc__, version="0.1.0")
    sentences = []
    for name in opts['CONLLFILE']:
        with open(name) as f:
            text = f.read()
            sentences.extend(text.split('\n\n'))
    shuffle(sentences)

    name, _ = splitext(opts['CONLLFILE'][0])

    with open(name+'.train.conll', 'w') as f:
        f.write('\n\n'.join(sentences[1:len(sentences)//2]))
        f.write('\n')

    rest = sentences[len(sentences)//2:]

    with open(name+'.test.conll', 'w') as f:
        f.write('\n\n'.join(rest[1:len(rest)//2]))
        f.write('\n')

    with open(name+'.verify.conll', 'w') as f:
        f.write('\n\n'.join(rest[len(rest)//2:]))
        f.write('\n')
