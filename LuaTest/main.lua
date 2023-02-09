local Promise = require "Promise"

local myPromise = Promise:new(function (resolve, reject)
    local a = 2
    local b = 1
    if b == 0 then
        reject("The divisor cannot be zero!")
    else
        resolve(a/b)
    end
end)

myPromise:next(
    function (result) return result .. ' and bar' end
):next(
    function (result) return result .. ' and bar again' end
):next(
    function (result) return result .. ' and again' end
):next(
    function (result) return result .. ' and again' end
):next(
    function (result) print(result) end
)

io.read()