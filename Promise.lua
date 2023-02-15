Promise = {
    PENDING = "pending",
    FULFILLED = "fulfilled",
    REJECTED = "rejected"
}

Promise.__index = Promise

function safeCall(func, resolve, reject, ...)
    local ret = {pcall(func, ...)}
    -- print("callTF: ", ret[1], " callRet: ", ret[2])
    if ret[1] then
        if resolve then
            resolve(ret[2])
        end
    else
        if reject then
            return reject(ret[2])
        end
    end
    -- 没有设置处理方法时有返回值
    return ret[2]
end

-- target = function(resolve, reject)
function Promise.new(executor)
    local ret = setmetatable({}, Promise)

    ret.status = Promise.PENDING
    ret.result = nil
    ret.resolveList = {}
    ret.rejectList = {}
    
    ret.resolve = function(value)
        -- 如果promise状态被改变过 就return出来
        if ret.status ~= Promise.PENDING then
            return
        end

        ret.result = value
        ret.status = Promise.FULFILLED
        for _, func in ipairs(ret.resolveList) do
            func(value)
        end
    end

    ret.reject = function(err)
        if ret.status ~= Promise.PENDING then
            return
        end

        ret.result = err
        ret.status = Promise.REJECTED
        for _, func in ipairs(ret.rejectList) do
            func(err)
        end
        -- 任何情况下都返回nil
        return nil
    end
    safeCall(executor, nil, ret.reject, ret.resolve, ret.reject)
    return ret
end

function Promise:next(onFulfilled, onRejected)
    
    function runNext(promise, value, resolve, reject)
        -- 处理循环调用
        if value == promise then
            reject(error("Chaining cycle detected!"))
            return;
        end

        -- 处理返回值value为promise
        if getmetatable(value) == Promise then
            value.next(function(newvalue)
                runNext(promise, newvalue, resolve, reject)
            end, function(errInfo)
                reject(errInfo)
            end)
        else
            resolve(value)
        end
    end

    local ret = nil
    -- 处理值穿透
    if type(onFulfilled) ~= "function" then
        onFulfilled = function(value) return value end
    end
    if type(onRejected) ~= "function" then
        onRejected = function(errInfo) error(errInfo) end
    end

    -- 将then处理函数放入队列
    if self.status == self.PENDING then
        ret = Promise.new(function(resolve, reject)
            self.resolveList.push(function(value)
                local calRet = safeCall(onFulfilled, nil, reject, value)
                -- calRet 为空时代表safeCall处理了异常情况
                if calRet then runNext(ret, calRet, resolve, reject) end
            end)
            self.rejectList.push(function(errInfo)
                local calRet = safeCall(onRejected, nil, reject, errInfo)
                if calRet ~= nil then runNext(ret, calRet, resolve, reject) end
            end)
        end) 
    else
        -- 直接执行next中的处理函数
        local doFunc = nil
        if self.status == self.FULFILLED then
            doFunc = onFulfilled
        else 
            doFunc = onRejected
        end
        ret = Promise.new(function(resolve, reject)
            local calRet = safeCall(doFunc, nil, reject, self.result)
            if calRet then runNext(ret, calRet, resolve, reject) end
        end)
    end
    return ret
end

-- 处理异常
function Promise:catch(onRejected)
    return self:next(nil, onRejected)
end

-- 任何情况下都执行callback
function Promise:finally(callback)
    return self:next(callback, callback)
end

-- 直接返回成功的Promise对象
function Promise.resolve(value)
    return Promise.new(function(resolve, reject)
        resolve(value)
    end)
end

-- 直接返回失败的Promise对象
function Promise.reject(errInfo)
    return Promise.new(function(resolve, reject)
        reject(errInfo)
    end)
end

-- 所有执行成功才成功
function Promise.all(promiseList)
    local count = #promiseList
    local retList = {}
    return Promise.new(function(resolve, reject)
        for index, promise in ipairs(promiseList) do
            promise.next(function(value)
                retList[index] = value
                count = count - 1
                if count == 0 then
                    resolve(retList)
                end
            end).catch(function(errInfo)
                reject(errInfo)
            end)
        end
    end)
end

-- 返回第一个执行成功的
function Promise.race(promiseList)
    return Promise.new(function(resolve, reject)
        for _, promise in ipairs(promiseList) do
            promise.next(function(value)
                resolve(value)
            end).catch(function(errInfo)
                reject(errInfo)
            end)
        end
    end)
end

-- 成功一个即返回成功
function Promise.any(promiseList)
    local count = #promiseList
    local errList = {}
    return Promise.new(function(resolve, reject)
        for index, promise in ipairs(promiseList) do
            promise.next(function(value)
                resolve(value)
            end).catch(function(errInfo)
                    errList[index] = errInfo
                    count = count - 1
                    if count == 0 then
                        reject(errList)
                    end
            end)
        end
    end)
end

-- 所有执行完即成功
function Promise.allSettled(promiseList)
    local count = #promiseList
    local retList = {}
    return Promise.new(function(resolve, reject)
        for index, promise in ipairs(promiseList) do
            promise.next(function(value)
                retList[index] = value
                count = count - 1
                if count == 0 then
                    resolve(retList)
                end
            end).catch(function(errInfo)
                retList[index] = errInfo
                count = count - 1
                if  count == 0 then
                    resolve(retList)
                end
            end)
        end
    end)
end

return Promise