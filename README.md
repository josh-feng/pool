# Pool & RML
---
## Poorman's object-oriented lua (Pool)

Lua itself provides rich features to implement some flavor of object-oriented programming.
The module, 'pool.lua', in 'src' folder is all we need.

**Example: Initialization**

    class = require('pool')
    base = class {
        field = 1;
    }
    v1, v2 = base(), base()
    print(v1.field + v2.field)    --> 2

**Example: Member Function**

Class member functions are first class values

    class = require('pool')
    base = class {
        -- member variables
        field = 2;

        -- member functions
        func1 = function (o, v)
           return math.pow(o.field, tonumber(v) or 1)
        end;
    }
    v1, v2 = base(), base()
    print(v1:func1(2) + v2:func1(3))    --> 12.0


**Example: Table Value Default**

    class = require('pool')
    base = class {
        field = {};
    }
    v1, v2 = base(), base()
    v1 field[1], v2.field[1] = 2, 3
    print(v1.field[1] + v2.field[1])    --> 5

**Example: Constructor/Destructor**

    class = require('pool')
    base = class {
        -- member variables
        field = {};

        -- constructor
        ['<'] = function (o, v)
            o.field[1] = v
        end;
        -- destructor
        ['>'] = function (o)
        end;
    }
    v1, v2 = base(1), base(2)
    print(v1:method(2) + v2:method(3))    --> 12.0

**Example: Member Function Overload**

Under construction.

**Example: Inheritage/Polymorphism**

Under construction.

**Example: Table Value Again**

Under construction.

**Example: Method (object type)**

Under construction.

**Notice**

Namespace/variable-privacy is do-able, but expensive with \_ENV
Class member functions are first class values

**Usage paradigm**

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

**Polymorphism/Inheritance**

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

---
## Reduced Markup Language (RML)

Several formats (xml, markdown, json, yaml, etc.) are not stable and/or have some limitations.
We will develop our own. The goal is to have a succinct format to break a text into usable fields.

    Syntax: RML works like punctutaions
        rml     := '#rml' [hspace+ [attr1]]* [vspace hspace* [assign | comment]]*
        hspace  := ' ' | '\t'
        vspace  := '\r'
        space   := hspace | vspace
        comment := '#' [pdata] [hspace | ndata]* '\r'
        assign  := [id] [prop1* | prop2] ':' [hspace+ [comment] [pdata | sdata]] [space+ (ndata | comment)]*
        prop1   := '|' [attr0 | attr1]
        prop2   := '|{' [comment+ [attr0 | attr2 ]]* vspace+ '}'
        attr0   := [&|*] id
        attr1   := id '=' ndata
        attr2   := id hspace* '=' (hspace+ | comment) [pdata | sdata]
        ndata   := [^space]+
        sdata   := ['|"] .* ['|"]
        pdata   := '<' [id] '[' id ']' .- '[' id ']>'

lrps.lua provide a basic/simple lua script to parse an RML file,
it can be coded to C/C++ lib for efficiency. In fact, lrp.so will be the C-module parser.
With lrps.lua or lrp.so, the script lrm.lua provide a sample lua object model builder for RML file
