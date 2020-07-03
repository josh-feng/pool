# Poorman's object-oriented lua (Pool)

Lua itself provides rich features to implement some flavors of object-oriented programming.
The module, 'pool.lua', in 'src' folder is all we need.


The design is to use the module return (function-)value as the *keyword*, **class**,
and then use this *keyword* to define a class
when calling **class** with a table-value argument as the class template.
A series of coding examples with increasing complexity will
follow the Usage paradigm.

**Usage paradigm**

```lua
class = require('pool')

myBaseClass = class {
    field = false;

    ['<'] = function (o, v) o.field ... end; -- constructor
    ['>'] = function (o) end;                -- destructor

    func1 = function (o, ...) o.field ... end;
}

o = myBaseClass(1)
o.field = o:func1(...)
```

- class variables are public, and addressed with '.'
- class memeber functions are public, and called with ':'
- constructor ['<'] is optional, and called when creating a new object
- destructor ['>'] is optional, and called by lua's garbage collector

**Example: Initialization**

Class member variables are all public. Undertermined member variables can be assigned with 'false'.

```lua
class = require('pool')     -- class 'keyword'
base = class {              -- the base class
    field = 1;
    old = false;
    new = false;
}
v1, v2 = base(), base()     -- instantiate
print(v1.field + v2.field)  --> 2
```

**Example: Member Function**

Class member functions are first class values

```lua
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
```

**Example: Table Value Default**

```lua
    class = require('pool')
    base = class {
        field = {};
    }
    v1, v2 = base(), base()
    v1 field[1], v2.field[1] = 2, 3
    print(v1.field[1] + v2.field[1])    --> 5
```

**Example: Constructor/Destructor**

```lua
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
```

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
