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

        -- 这里需要异步调用
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

return Promise