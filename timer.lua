declare_module{
   name = "Timer",
   author = "Alexander Yarygin",
   type = "hardware",
   description = "",
   params = { },
   interface = {
      functions = {},
      events = {
         { name = "timerInterrupt",
           params = { { name="NodeID", type="uint16" },
                      { name="Type", type="string" } } },

      }
   },
   dependencies = { }
}

Timer = {}

function Timer:interface()
   return { start = function (timeout, type) self:start(timeout, type) end }
end

function Timer:init(params, interfaces)
   self.node = params.parentNode
end

function Timer:start(timeout, type)
   Simulator.postEvent{ author = self,
                        event = "timerInterrupt",
                        delay = timeout,
                        args = { type } }
end
