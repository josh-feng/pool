# pool
Poorman's object-oriented lua

    Variable privacy is do-able, but expensive
    No namespace
    Functions are first class values

Usage paradigm

    class = require('pool')
    myBaseClass = class {
        field = false;
        ['<'] = function (o, v) o.field = v or o.field end; -- constructor
        ['>'] = function (o) end;                           -- destructor
        func1 = function (o, ...) ... end;
    }
    o = myBaseClass(1)
    o.field = o:func1(...)

    class variables are public, and addressed with '.'
    class memeber functions are public, and called with ':'

For polymorphism/inheritance:

    myChildClass = class {
        { myBaseClass;                      -- parent class
            __add = function (o1, o2)       -- o1 + o2
                local o = class:copy(o1)
                o.field = o1.field + o2.field
                ...
                return o
            end;
        };
        newfield = false;
    }
    o1 = myChildClass(1)
    o2 = myChildClass(2)
    print((o1 + o2).field)

Project: Reduced Markup Language (RML)

    Several formats (markdown, json, yaml, etc.) are not stable and have some limitation/drawbacks.
    We will develop our own.  The goal is have a succinct format to break a text into usable fields.

    Syntax: RML works like punctutaions
       rml     := '#rml' [blank+ [attr1]]* blank* '\r' [assign | blank* comment]*
       blank   := ' ' | '\t'
       space   := [blank | '\r']+
       assign  := blank* [id] [prop1* | prop2] ':' [blank+ (pdata | sdata)] [[space (ndata | comment)]* '\r']+
       comment := '#' ([^\r]*' '\r' | pdata)
       prop1   := '|' [attr0 | attr1]
       prop2   := '|{' space [blank* [[attr0 | attr2]] space comment* '\r']* '}'
       attr0   := id
       attr1   := id '=' ndata
       attr2   := id blank* '=' [blank+ (pdata | sdata)]
       pdata   := '<' [id] '[' id ']' .* '[' id ']>'
       sdata   := ['|"] .* ['|"] {C-string}
       ndata   := \S+ {' \#' is replaced w/ ' #'}
