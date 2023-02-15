local Promise = require("Promise")

Promise.new(function(resolve, reject)
    print(0)
    resolve(1)
end):next(function(value)
    print(value)
    return value * 2
end):next():next(function(value)
    print(value)
    return value * 2
end)

io.read()