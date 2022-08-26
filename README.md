# Poorman's object-oriented lua (Pool)

Lua itself provides rich features to implement some flavors of object-oriented programming
in scripting level.
This table-based OO module is implemented in a single file (**src/pool.lua**).

The design is to use the module returned value as the *keyword* '**class**' for defining classes.
On invoking this *keyword* with a table as the class template, an object creator function is returned.
Objects are generated when calling object creators.

## Usage paradigm

```lua
class = require('pool')

-- object creator based on the class template
myBaseClass = class {
    field = false;

    func1 = function (o, ...) o.field ... end;

    ['<'] = function (o, v) o.field ... end; -- constructor
    ['>'] = function (o) ... end;            -- destructor

    ['^'] = { -- object operators: based on lua meta-method features
        __add = function (o, ...) ... end;
        ...
    };
}

-- create an object (table-based)
o1, o2 = myBaseClass(1), myBaseClass(2)
o1.field = o1:func1(...)

print(o1 + o2)              -- table-structure operators
```

- class variables are public, and addressed with **`.`**
- class memeber functions are public, and called with **`:`**
- constructor **`['<']`** is optional, and called when creating a new object
- destructor **`['>']`** is optional, and called by lua's garbage collector
- operator table **`['^']`** is optional, based on lua's meta-methods. 

**Example: Initialization**

The class is handled thru the object creator.
Class member variables are all public.
We usually set member variables 'false' as the default.

```lua
class = require('pool')     -- class 'keyword'
base = class {              -- the base class
    field = 1;

    __init = false;         -- not the constructor, just a regular entry
    new = false;            -- not the constructor, just a regular entry
}

v1, v2 = base(), base()     -- new objects (instantiate)

print(v1.field + v2.field)  --> 2
print(v1.__init)            --> false

v1.old = true               --> error: creating a new entry is not allowed

v1 = nil                    -- delete the object
```

All entries should be declared in the class template.

**Example: Member Function**

Since functions are first class values in Lua,
changing member functions to other types is possible, but a bad practice.

The guideline is to put the object as the first argument for member functions.
In C++, it would be called 'this', and Lua would use 'self'.
However, the member function is defined in the scope of the class template table,
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

In setting a member variable with a table as the default, non-string indexed entry will be ignored.
However, non-string indexed entry can be implemented in the constructor.

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

The 'field' member in the above example points to separate tables for object 'v1' and 'v2'.
Using the *metatable* mechanism,
we light-copy every table value in the class template for each object in initialization.
This is useful in most applications.
Making a member entry of a class pointing to a specific table can be done in the constructor.


**Example: Constructor/Destructor**

When choosing entry names for constructor and destructor,
we leave the traditional names, such as 'new' and '\_\_init', for reqular use;
instead, the special names, '<' and '>', are reserved for them.
The constructor can take more arguments.

```lua
class = require('pool')

local linktable = {}

base = class {
    -- member variables
    old = 0;
    new = 1;
    _init = 2;
    field = {};
    link = false;

    -- constructor
    ['<'] = function (o, v)
        o.field[1] = v
        o.link = linktable -- all objects share the same linktable
    end;
    -- destructor
    ['>'] = function (o)
    end;
}

v1, v2 = base(1), base(2)
print(v1.field[1] + v2.field[1])    --> 3
print(v1['<'])                      --> nil
```

The constructor and destructor are not accessible directly.

**Example: Member Function Override**

Defined class is handled thru the object creator.
Member functions can be overridden in objects,
while the class member function is intact as in the class template.

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

**Example: Inheritance/Polymorphism and Operators**

The parent class is supplied as the only argument for the keyword
**class**, then the derived class template follows right afterwards.
Lua's table **operator** feature is supported.
The entry **`['^']`** is used for the object's *meta-table*.
Operators are defined in this *meta-table*.
Derived class can have differnt operators from the parrent class.

```lua
class = require('pool')
base = class {
    value = 1;
    variant = 1;

    ['<'] = function (o, v) o.value = v or o.value end; -- o is the object

    ['^'] = { -- metatable: operator
        __add = function (o1, o2)
            local o = class:new(o1)
            o.value = o1.value - o2.value
            return o
        end;
    };
}

test = class (base) { -- 'base' is the parent class
    extra = {};

    ['<'] = function (o, v) o.extra = (v or -1) + o.value end; -- overridden

    ['^'] = { -- metatable:
        __add = function (o1, o2) return o1.value + o2.value end; -- override
    };
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

The constructors and destructors through inheritance are called in chain.
Only single parent inheritance is supported.

- **class:parent(o)** returns the parent class (its object creator)
- **class:new(o)** returns the duplicate object after calling the constructor
- **class:copy(o)** returns the duplicate object without calling the constructor

**Example: Release/Reset/Recover**

Creating new member entries is not allowed.
Only string-indexed members are supported.
Assigning nil to member entries resets them to the default.

```lua
class = require('pool')
base = class {
    value = 0;
    method = function (o, v) o.value = v or o.value end;
}

v = base()

v.method = 1        --> bad practice, but legal
print(v.method)     --> 1
v.method = nil      --> reset to the default function
v:method(2)
print(v.value)      --> 2
```

**Example: Table Value (including Object Value) Again**

Since table value is lightly copy for objects in initialization
if table value is used in the class template,
it will be reset to *false* when assigned nil.
There is no way to invoke initialization again for member variables.
Similarly for object values,
setting nil will reset *false* instead.

```lua
class = require('pool')
base = class {
    value = 0;
}

newClass = class { -- friend class
    friend = base();
}

v = newClass()
print(v.friend.value)   --> 0
v.friend = nil
print(v.friend)         --> false
w = newClass()
print(w.friend.value)   --> 0

x = v                   -- same object
y = w()                 -- fast duplicate
```

Since object is essentially a table, object assignment will make new variable point to the same object.
Using object's \_\_call method will fast copy the object.

**Example: More on Polymorphism**

The order of constructors and destructors in polymorphism is shown below:

```lua
class = require('pool')
base = class {
    item = true;
    value = 1;
    ['<'] = function (o, v) print('base', o.value) end;
    ['>'] = function (o) print('base object is gone') end;
}

main = class (base) {
    value = { item = 0 };
    ['<'] = function (o, v) print('main', o.value) end;
    ['>'] = function (o) print('main object is gone') end;
}

derived = class (main) {
    value = 0;
}

v = derived()   --> base    0
                --> main    0
print(v.item)   --> true
v = nil         --> main object is gone
                --> base object is gone
```

## Notice

Lua is a scripting language, not a strong type programming language.
If you are a hardcore object-oriented programer seeking
the most advanced OOP features,
then you would choose C++ or other languages.

- Namespace/variable-privacy is do-able, but expensive with **\_ENV** mechanism.
- New entries are prehibited
- Object memebers can be recovered to the default value by assigning nil.

Breaking the usage paradigm is possible, but not recommanded.
Usually it involves some up-vales.

```lua
alias = function (o) print('version 1') end

myClass = class {
    method = function (o, ...) alias(o, ...) end;
}

o = myClass()
o:method()      --> version 1

alias = function (o) print('version 2') end
o:method()      --> version 2
```


The `class` table provides a mechanism to access class templates
(i.e. object's meta-table).
Extending/Modifying classes is still possible after they are defined:

```lua
class = require('pool')

myClass = class {}  -- dummy declaration

myClassTmpl = class[myClass].__index

o = myClass()

print(o.field)      --> nil

myClassTmpl.field = 1
myClassTmpl.func1 = function (o) print(o.field) end

print(o.field)      --> 1
o:func1()           --> 1
```

The `tostring` function will return object's class table hash number.


Please check out many applications in the 'examples' folder, and the files in 'doc' folder, too.

