module CoreNLP

export corenlp_init, pprint, parse, batch_parse

using JSON
using PyCall

py_nlp = nothing

function corenlp_init(nlp_path="corenlp"; kwargs...)
    global py_nlp
    py_nlp_module = load_nlp_module()
    py_nlp = pycall(py_nlp_module[:StanfordCoreNLP], PyObject, nlp_path; kwargs...)
end

function load_nlp_module()
    p = joinpath(Pkg.dir("CoreNLP"), "python")
    unshift!(PyVector(pyimport("sys")["path"]), p)
    py_nlp_module = pyimport("corenlp")
end

immutable Word
    lex::String
    lemma::String
    ne_tag::Symbol
    pos::Symbol
    start_pos::Int
    end_pos::Int
end

immutable DepNode
    word::Int
    parent::Int
    tag::Symbol
end

immutable DepParse
    nodes::Vector{DepNode}
end

immutable Sentence
    dep_parse::DepParse
    words::Vector{Word}
end

immutable Mention
    sentence::Int
    start_pos::Int
    end_pos::Int
    head::Int
end

immutable Coref
    mentions::Vector{Mention}
    repr::Mention
end

immutable Annotated
    sentences::Vector{Sentence}
    corefs::Vector{Coref}
    file_name::String
end


Mention() = Mention(0, 0, 0, 0)

Coref(repr::Mention) = Coref(Mention[], repr)
Coref() = Coref(Mention[], Mention())

DepParse() = DepParse(DepNode[])

Sentence() = Sentence(DepParse(), Word[])

Annotated(file_name="") = Annotated(Sentence[], Coref[], file_name)

function pprint(io::IO, a::Annotated)
    pprint(io, a.corefs, a)
    pprint(io, a.sentences)
end

function pprint(io::IO, corefs::Vector{Coref}, a::Annotated)
    for coref in corefs
        print(io, "Coreferencing \"")
        pprint(io, coref.repr, a)
        print(io, "\":\n")
        for m in coref.mentions
            pprint(io, m, a)
            print(io, "\n")
        end         
        println(io)
    end
end

function pprint(io::IO, sentences::Vector{Sentence})
    for (i, s) in enumerate(sentences)
        println("Sentence ", i, ":")
        pprint(io, s)
        println(io)
    end
end

function pprint(io::IO, m::Mention, a::Annotated)
    s = a.sentences[m.sentence]
    words = s.words[m.start_pos:m.end_pos]
    print(io, join([_.lex for _ in words], " "))
    print(io, " (", m, ")")
end

function pprint(io::IO, s::Sentence)
    println(io, "Words:")
    print(io, s.words)
    println(io, "Dependency parse:")
    for node in s.dep_parse.nodes
        pprint(io, node, s)
        println(io)
    end
end

function pprint(io::IO, n::DepNode, s::Sentence)
    lex_child = s.words[n.word].lex
    lex_parent = n.parent == 0 ? "ROOT" : s.words[n.parent].lex
    @printf(io, "%s <=(%s) %s", lex_child, n.tag, lex_parent)
end

pprint(io::IO, s::String) = pprint(io, parse(s))

pprint(a) = pprint(STDOUT, a)

function extract_index(s)
    m = match(r"-(\d+)$", s)
    idx = int(m.captures[1])
    return idx
end

function parse_mention(m)
    sentence = int(m[2])+1
    start_pos = int(m[4])+1
    end_pos = int(m[3])+1
    head_pos = int(m[5]) # should this be +1 too?
    return Mention(sentence, start_pos, end_pos, head_pos)
end

function parse_json(j, args...)
    parse_raw(JSON.parse(j), args...)
end

macro get(e)
    name = e.args[1]
    dict = e.args[2].args[1]
    key = e.args[2].args[2]
    quote
        $(esc(name)) = get($(esc(dict)), $(esc(key)), "")
    end
end

function parse_raw(p, dep_type=:py)
    file_name = get(p, "file_name", "")
    ann = Annotated(file_name)
    if haskey(p, "sentences")
        for sentence in p["sentences"]
            s = Sentence()
            if dep_type == :py
                if haskey(sentence, "indexeddependencies")
                    for parse_part in sentence["indexeddependencies"]
                        tag = parse_part[1]
                        parent_idx = extract_index(parse_part[2])
                        child_idx = extract_index(parse_part[3])
                        push!(s.dep_parse.nodes, DepNode(child_idx, parent_idx, tag))
                    end
                end
            else
                if haskey(sentence, "dependencies")
                    deps = sentence["dependencies"]
                    for i in 1:size(deps, 1)
                        tag = deps[i][1]
                        parent_idx = int(deps[i][2])
                        child_idx = int(deps[i][3])
                        push!(s.dep_parse.nodes, DepNode(child_idx, parent_idx, tag))
                    end
                end
            end
            if haskey(sentence, "words")
                words = sentence["words"]
                for i in 1:size(words, 1)
                    head = words[i][1]
                    props = words[i][2]
                    @get lemma = props["Lemma"]
                    @get tag = props["NamedEntityTag"]
                    @get pos = props["PartOfSpeech"]
                    start_pos = int(props["CharacterOffsetBegin"])
                    end_pos = int(props["CharacterOffsetEnd"])
                    push!(s.words, Word(head, lemma, tag, pos, start_pos, end_pos))
                end
            end
            push!(ann.sentences, s)
        end
    end
    if haskey(p, "coref")
        for coref in p["coref"]
            c = Coref(parse_mention(coref[1][2]))
            for mention in coref
                source = mention[1]
                sink = mention[2]
                push!(c.mentions, parse_mention(source))
            end
            push!(ann.corefs, c)
        end
    end
    return ann
end

function check_init()
    py_nlp == nothing && error("Must call corenlp_init() first")
end

function parse(s)
    check_init()
    j = py_nlp[:parse](s)
    return parse_json(j)
end

function batch_parse(dir, corenlp_dir; kwargs...)
    py_nlp_module = load_nlp_module()
    gen = pycall(py_nlp_module["batch_parse"], PyObject, dir, corenlp_dir; kwargs...)
    list = pyeval("list(gen)", PyVector, gen=gen)
    ann_list = map(x->parse_json(x, :raw), list)
    d = [ann.file_name=>ann for ann in ann_list]
    return d
end

end