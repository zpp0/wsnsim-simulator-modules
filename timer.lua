declare_module{
   name = "Timer",
   author = "Alexander Yarygin",
   type = "hardware",
   description = "Точный таймер",
   interface = {
      functions = {
         { name = "start", info = "запустить таймер",
           args = { { name = "timeout", type = "uint64", info = "время, через которое произойдет прервание" },
                    { name = "type", type = "string", info = "тип прерывания" } } }
      },
      events = {
         { name = "timerInterrupt",
           params = { { name="NodeID", type="uint16" },
                      { name="Type", type="string" } } },

      }
   },
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
