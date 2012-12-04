declare_module{
   name = "APL",
   author = "Alexander Yarygin",
   type = "software",
   description = "",
   params = { },
   interface = { },
   dependencies = {
      { name = "TRX", type = "hardware",
        interface = { } },
      { name = "Timer", type = "hardware",
        interface = {
           functions = {
              { name = "start", info = "запускает таймер",
                args = {
                   { name = "interruptType", type = "string" } } }
           }
     } },
      { name = "Scene", type = "environment",
        interface = {} },
   }
}

APL = {}

function APL:interface()
   return {}
end

function APL:init(params, interfaces)
   self.node = params.parentNode
   self.TRX = interfaces.TRX
   self.Timer = interfaces.Timer

   Simulator.handleEvent{ author = "Scene",
                          event = "nodePowerUp",
                          handler = "main" }
   Simulator.handleEvent{ author = "Timer",
                          event = "timerInterrupt",
                          handler = "interruptHandler" }
end

function APL:main()
   self.Timer.start(1000, "attemptSendMessage")
end

function APL:interruptHandler(type)
   if (self.TRX.CCA() == true) then
      local message = { self.node, 10, 11, 12, 13, 14, 15 }
      self.TRX.startTX(message)
   end
   self.Timer.start(1000, "attemptSendMessage")
end