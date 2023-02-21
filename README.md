# lua-promise

easy promise implemented by lua

# Installation

add "promise.lua" file to your workpath and require it

```lua
local Promise = require("Promise")
```

# Use

* promise.new()
```lua
p1 = Promise.new(function(resolve, reject)
  -- anything you can do
end)
```
* next（then）
```lua
p1 = Promise.new()
p1:then(function(value)
  -- Here is some code that can be used 
  -- to handle scenarios where a promise is resolved.
end, function(errInfo)
  -- Another situations when promise is rejected
end)
```
* catch
```lua
p1 = Promise.new()
p1:catch(function(errInfo)
  -- Especially used to handle rejected situations
end)
```
* finally
```lua
p1 = Promise.new()
p1:finally(function(value)
  -- some code that takes effect in all cases
end)
```
* Promise.resolve()/Promise.reject()
```lua
-- construct a Fulfilled/Rejected promise
p1 = Promise.resolve("WOW")
p2 = Promise.reject("No")
```
* Promise.all()
```lua
promiseList = {}
promiseList[1] = Promise.new()
promiseList[2] = Promise.new()
promiseList[3] = Promise.new()
p = Promise.all(promiseList)
-- p will resolve once all items in promiseList have been resolved
```
* Promise.race()
```lua
p = Promise.race(promiseList)
-- Once any item in promiseList have been resolved first
```
* Promise.any()
```lua
p = Promise.any(promiseList)
-- One of the items in promiseList have been resolved
```
* Promise.allSettled()
```lua
p = Promise.allSettled(promiseList)
-- Every items in promiseList have been resolved/rejected
```

