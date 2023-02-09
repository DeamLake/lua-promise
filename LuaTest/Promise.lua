Promise = {}

function Promise:new(func)
    local obj = setmetatable(
        {status = "pending", result = nil,  err = nil }, 
        {__index = self }
    )

    local resolve = function(ret)
        obj.status = "fulfilled"
        obj.result = ret
    end

    local reject = function(errinfo)
        obj.status = "rejected"
        obj.err = errinfo
    end

    func(resolve, reject)
    return obj
end

function Promise:next(handleFulfilled, handleRejected)
    if self.status == "fulfilled" then
        self.result = handleFulfilled(self.result)
    elseif self.status == "rejected" then
        self.err = handleRejected(self.err)
    end

    return self
end

return Promise