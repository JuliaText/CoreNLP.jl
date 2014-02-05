CoreNLP.jl
==============

An interface to [Stanford's CoreNLP toolkit](http://nlp.stanford.edu/software/corenlp.shtml) via the [corenlp-python bindings](https://bitbucket.org/torotoki/corenlp-python). 

Features
----------
State-of-the-art dependency parsing, part-of-speech tagging, coreference resolution, tokenization, lemmatization, and named-entiy recognition for English text. 

Installation
--------------
You must have Python 2.7 installed in a place where [PyCall](https://github.com/stevengj/PyCall.jl) can find it. The Enthought distribution has proven problematic, but Anaconda works fine. 

1. Install CoreNLP.jl from the Julia REPL:
```julia
Pkg.clone("CoreNLP")
```

2. [Download the CoreNLP package](http://nlp.stanford.edu/software/corenlp.shtml#Download) and unzip it to a location of your choosing. Direction download link: [Version 3.3.1](http://nlp.stanford.edu/software/stanford-corenlp-full-2014-01-04.zip).

Usage
-------
```julia
> using CoreNLP
> corenlp_init("/Users/malmaud/stanford-corenlp-full-2014-01-04") # Replace this with wherever you extracted Stanford's CoreNLP toolkit to. This may take a few minutes to execute as the large statistical language models are loaded into memory.
> my_parse = parse("This is a simple sentence. We will see how well it parses.")
> my_parse.sentences[2].dep_parse # The dependency parse for the second sentence.
> my_parse.corefs[1].mentions # The set of all mentions that correspond to my_parse.corefs[1].repr (The representative mention)
> pprint(my_parse) # Pretty-printing
```

This outputs
``
Coreferencing  (Mention(1,5,3,5)):
This (Mention(1,1,1,1))
it (Mention(2,6,6,6))

Sentence 1:
Words:
Word("This","this","O","DT")
Word("is","be","O","VBZ")
Word("a","a","O","DT")
Word("simple","simple","O","JJ")
Word("sentence","sentence","O","NN")
Word(".",".","O",".")
Dependency parse:
sentence <=(root) ROOT
This <=(nsubj) sentence
is <=(cop) sentence
a <=(det) sentence
simple <=(amod) sentence

Sentence 2:
Words:
Word("We","we","O","PRP")
Word("will","will","O","MD")
Word("see","see","O","VB")
Word("how","how","O","WRB")
Word("well","well","O","RB")
Word("it","it","O","PRP")
Word("parses","parse","O","VBZ")
Word(".",".","O",".")
Dependency parse:
see <=(root) ROOT
We <=(nsubj) see
will <=(aux) see
how <=(advmod) well
well <=(advmod) parses
it <=(nsubj) parses
parses <=(ccomp) see
``