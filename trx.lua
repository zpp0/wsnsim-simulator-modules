declare_module{
   name = "TRX",
   author = "Alexander Yarygin",
   type = "hardware",
   description = "Радио приемник-передатчик",
   params = {
      { name = "RXSensivity", type = "double", info = "Чувствительность приемника" },
      { name = "TXPower", type = "double", info = "Мощность передатчика" }
   },
   interface = {
      functions = {
         { name = "state", info = "возвращает состояние приемника-передатчика" },
         { name = "TXPower", info = "возвращает мощность приемника-передатчика" },
         { name = "RXSensivity", info = "возвращает чувствительность приемника-передатчика" },
         { name = "CCA", info = "возвращает true, если канал свободен, false если занят" },
         { name = "setPower", info = "изменяет состояние приемника-передатчика. Включает, если аргумент равен true, выключает, если false",
           args = { { name = "state", type = "bool" } } },
         { name = "startTX", info = "начать передачу сообщения",
           args = { { name = "message", type = "byteArray" } } },
      },
      events = {
         { name = "messageDropped",
           params = {
              { name = "NodeID", type = "uint16" },
              { name = "message", type = "ByteArray" } } },

         { name = "SFD_RX_Down",
           params = {
              { name = "NodeID", type = "uint16" },
              { name = "message", type = "ByteArray" } } },

         { name = "SFD_RX_Up",
           params = {
              { name = "NodeID", type = "uint16" },
              { name = "message", type = "ByteArray" },
              { name = "RSSI", type = "double" } } },

         { name = "SFD_TX_Down",
           params = {
              { name = "NodeID", type = "uint16" } } },

         { name = "SFD_TX_Up",
           params = {
              { name = "NodeID", type = "uint16" },
              { name = "message", type = "ByteArray" },
              { name = "TXPower", type = "double" } } },

         { name = "CCA",
           params = {
              { name = "NodeID", type = "uint16" },
              { name = "State", type = "bool" } } },

         { name = "collision",
           params = {
              { name = "NodeID", type = "uint16" } } },

         { name = "MessageReceived",
           params = {
              { name = "NodeID", type = "uint16" },
              { name = "message", type = "ByteArray" } } },

         { name = "MessageSent",
           params = {
              { name = "NodeID", type = "uint16" } } }

      }
   },
   dependencies = {
      { name = "Radio", type = "environment",
        interface = {
           functions = {
              { name = "send", info = "отправить сообщение в канал",
                args = {
                   { name = "sender", type = "uint16", info = "ID узла отправителя" },
                   { name = "message", type = "byteArray", info = "тело сообщения" } } },
              { name = "aroundPower", info = "получить текущую мощность сигнала на узле",
                args = {
                   { name = "node", type = "uint16", info = "ID узла" } } }
           },
           events = {
              { name = "newMessageInChannel",
                params = { { name="message", type="ByteArray" },
                           { name="RSSI", type="double" } } },
           }
        },
     },
   }
}

TRX = { }

function TRX:interface()
   return { setPower = function(on) self:setPower(on) end,
            startTX = function(message) self:startTX(message) end,
            CCA = function() return self:CCA() end,
            TXPower = function() return self:TXPower() end,
            RXSensivity = function() return self:RXSensivity() end,
            state = function() return self:state() end }
end

function TRX:init(params, interfaces)
   self.mRXSensivity = params.RXSensivity
   self.mTXPower = params.TXPower
   self.parentNode = params.parentNode

   self.radio = interfaces.Radio

   self.mstate = "Free"

   Simulator.handleEvent{ author = "Radio",
                          event = "newMessageInChannel",
                          handler = "listen" }

   Simulator.handleEvent{ event = "SFD_RX_Up",
                          handler = "SFD_RX_Up_interrupt" }

   Simulator.handleEvent{ event = "SFD_RX_Down",
                          handler = "SFD_RX_Down_interrupt" }
   Simulator.handleEvent{ event = "SFD_TX_Up",
                          handler = "SFD_TX_Up_interrupt" }
   Simulator.handleEvent{ event = "SFD_TX_Down",
                          handler = "SFD_TX_Down_interrupt" }

end

function TRX:setPower(on)
   if (on == true and self.state == "Off") then
      self.mstate = "Free"

   elseif (on == false) then

      if (self.mstate == "RXON") then
         Simulator.postEvent{ author = self,
                              event = "messageDropped",
                              args = { {} } }
      end

      self.mstate = "Off"
   end
end

function TRX:startTX(message)
   table.insert(message, 1, #message)

   Simulator.postEvent{ author = self,
                        event = "SFD_TX_Up",
                        args = { message, self.mTXPower } }

   self.radio.send(self.parentNode, message)

   local timeTXEnd = (#message + 5) * 32;

   Simulator.postEvent{ author = self,
                        event = "SFD_TX_Down",
                        args = { } }
end

function TRX:CCA()
   local state = self.radio.aroundPower(self.parentNode)

   Simulator.postEvent{ author = self,
                        event = "CCA",
                        args = { state } }

   return state
end

function TRX:TXPower()
   return self.mTXPower
end

function TRX:RXSensivity()
   return self.mRXSensivity
end

function TRX:state()
   return self.mstate
end

function TRX:listen(message, rssi)
   if (self.mstate == "Free") then
      Simulator.postEvent{ author = self,
                           event = "SFD_RX_Up",
                           args = { message, rssi} }
   else
      Simulator.postEvent{ author = self,
                           event = "collision",
                           args = {  } }

      Simulator.postEvent{ author = self,
                           event = "messageDropped",
                           args = { message } }
   end
end

function TRX:SFD_RX_Up_interrupt(message, rssi)
   if (self.mstate ~= "TXON") then
      self.mstate = "RXON"
      Simulator.postEvent{ author = self,
                           event = "SFD_RX_Down",
                           delay = #message * 32,
                           args = { message } }
   end
end

function TRX:SFD_RX_Down_interrupt(message)
   if (self.mstate == "RXON") then

      self.mstate = "Free"
      Simulator.postEvent{ author = self,
                           event = "MessageReceived",
                           args = { message } }

   end
end

function TRX:SFD_TX_Up_interrupt(message, TXPower)
   if (self.mstate == "Free") then
      self.mstate = "TXON"
   end
end

function TRX:SFD_TX_Down_interrupt()
   if (self.mstate == "TXON") then
      self.mstate = "Free"
      Simulator.postEvent{ author = self,
                           event = "MessageSent",
                           args = { } }
   end
end
