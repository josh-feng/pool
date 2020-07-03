# Poorman's object-oriented lua (Pool)

Lua itself provides rich features to implement some flavors of object-oriented programming.
The module, 'pool.lua', in 'src' folder is all we need.

The design is to use the module return value as the *keyword*, **class**,
for defining classes.
On invoking this *keyword* with a table as the class template,
a object creator function is returned.
Objects are generated when calling object creators.

A series of coding examples with increasing complexity show the supporting features.

## Usage paradigm

```lua
class = require('pool')

myBaseClass = class {
    field = false;

    ['<'] = function (o, v) o.field ... end; -- constructor
    ['>'] = function (o) end;                -- destructor

    func1 = function (o, ...) o.field ... end;
}

o = myBaseClass(1)      -- create a object
o.field = o:func1(...)
```

- class variables are public, and addressed with **'.'**
- class memeber functions are public, and called with **':'**
- constructor **['<']** is optional, and called when creating a new object
- destructor **['>']** is optional, and called by lua's garbage collector

**Example: Initialization**

Class member variables are all public.
Member variables usually have 'false' as the default.
The defined class is handled thru the returned object creator.

```lua
class = require('pool')     -- class 'keyword'
base = class {              -- the base class == object creator
    field = 1;
    old = false;
    new = false;
}
v1, v2 = base(), base()     -- instantiate
print(v1.field + v2.field)  --> 2
```

**Example: Member Function**

Class member functions are first class values,
changing their values is possible but a bad practice.

The first argument for member function is the object.
In C++, it would be called 'this', and lua would use 'self'.
However, it is defined in the class template table,
so we use **'o'** to represent the object.

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
v1.func1 = 1                        -- bad practice
```

**Example: Table Value Default**

Non-string index entry in the default table value will be ignored.
However, it can be implemented in the constructor.

```lua
class = require('pool')
base = class {
    field = {
        0;                  -- ignored
        item = 1;
    };
}
v1, v2 = base(), base()

print(v1.field[1])                  --> nil

v1.field[1], v2.field[1] = 2, 3
print(v1.field[1] + v2.field[1])    --> 5

v1.field.item = 2
print(v1.field.item + v2.field.item)    --> 3
```

**Example: Constructor/Destructor**

We leave the traditional entry names, such as 'new' and '\_init', for reqular use.
The special names, '<' and '>', are reserved,
and the constructor can take more arguments.

```lua
class = require('pool')
base = class {
    -- member variables
    old = 0;
    new = 1;
    _init = 2;
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
print(v1.field[1] + v2.field[1])    --> 3
print(v1.['<'])                     --> nil
```

The constructor and destructor are not accessible.

**Example: Member Function Override**

Defined class is handled thru the object creator.
Member functions can be overridden in objects,
but the class member function is intact as in the class template.

Object member variable/function can be recovered when assigned **'nil'**.

```lua
class = require('pool')
base = class {
    field = false;
    ['<'] = function (o, v) o.field = o:method(v) end;
    method = function (o, v)
        v = tonumber(v) or 1
        return v * v
    end;
}
v1 = base(1)
v1.method = function (o, v) o.field = 2 * v end
v2 = base(3)
print(v1.field, v2.field)   --> 1  9

print(v1:method(3))         --> 6
v1.method = nil
print(v1:method(3))         --> 9
```

**Example: Inheritage/Polymorphism**

Lua's table operator feature is supported.
If the firt entry of the class template is a table,
which is used for the object's *meta-table*.
Operators are defined in this *meta-table*.
If the first entry of this *meta-table* is a defined class,
it will be used as the parent class.
Derived class can have differnt operators from the parrent class.

```lua
class = require('pool')
base = class {
    value = 1;
    variant = 1;

    { -- metatable: operator
        __add = function (o1, o2)
            local o = class:new(o1)
            o.value = o1.value - o2.value
            return o
        end;
    };

    ['<'] = function (o, v) o.value = v or o.value end; -- o is the object
}

test = class {
    extra = {};

    { -- metatable: inherit class 'base'
        base;
        __add = function (o1, o2) return o1.value + o2.value end; -- override
    };

    ['<'] = function (o, v) o.extra = (v or -1) + o.value end; -- overridden
}

obj1, obj2, obj3 = base(3), test(2), test()

if -- failing conditions:
    obj1.value ~= 3 or obj2.extra ~= 4 or obj3.value ~= 1 -- constructor
    or obj2.variant ~= 1 or obj3.extra ~= 0 -- inheritance
    or ((obj1 + obj2).value ~= 1) -- operator following base obj1
    or (obj2 + obj3 ~= 3) -- operator following base obj2
    or (class:parent(test) ~= base) -- aux function
    or pcall(function () obj2.var = 1 end) -- object making new var
    or pcall(function () obj3['<'] = 1 end) -- object constructor
    or pcall(function () class(1) end) -- bad class declaration
then error('Class QA failed.', 1) end
```

**Example: Table Value Again**

Under construction.

**Example: Method (object type)**

Under construction.

## Notice

Namespace/variable-privacy is do-able, but expensive with \_ENV
Class member functions are first class values

**Polymorphism/Inheritance**

```lua
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
```

