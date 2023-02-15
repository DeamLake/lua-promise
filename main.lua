local Promise = require("Promise")

local promiseList = {}
promiseList[1] = Promise.new()
promiseList[2] = Promise.resolve("1")
promiseList[3] = Promise.resolve("1")
p = Promise.all(promiseList)


io.read()