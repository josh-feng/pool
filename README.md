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

Project: Alternative Markup Language (AML)

    Syntax:
