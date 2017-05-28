# pool
programming object-oriented lua

    Variable privacy is doable, but expensive
    No namespace
    Functions are first class values
    Extra destructor calls for derived classes
    
Usage paradigm

    class = require('pool')
    myBaseClass = class {
        field = false;
        [':'] = function (o, v) o.field = v or o.field end; -- constructor
        [';'] = function (o) end;                           -- destructor
    }
    obj1 = myBaseClass(1)
    
For polymorphism:
