declare_module{
   name = "Radio",
   author = "Alexander Yarygin",
   type = "environment",
   description = "Радиоканал",
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
           params = { { name="NodeID", type="uint16" },
                      { name="message", type="ByteArray" },
                      { name="RSSI", type="double" } } },
         { name = "changeLink",
           params = { { name="NodeID", type="uint16" },
                      { name="NodeID2", type="uint16" },
                      { name="rssi", type="double" } } }
      }
   },
   dependencies = {
      { name = "Scene", type = "environment",
        interface = {
           functions = {
              { name = "distance", info = "возвращает расстояние между двуми узлами",
                args = {
                   { name = "NodeID1", type = "uint16" },
                   { name = "NodeID2", type = "uint16" } } }
           },
           events = {
              { name = "nodePowerUp",
                info = "Включение узла",
                params = { { name = "NodeID", type = "uint16" } } } }
        },
     },
      { name = "TRX", type = "hardware",
        interface = {
           functions = {
              { name = "state", info = "возвращает состояние приемника-передатчика" },
              { name = "TXPower", info = "возвращает мощность приемника-передатчика" },
              { name = "RXSensivity", info = "возвращает чувствительность приемника-передатчика" }
           },
           events = {
              { name = "collision",
                params = { { name = "NodeID", type = "uint16" } } },
              { name = "messageDropped",
                params = {
                   { name = "NodeID", type = "uint16" },
                   { name = "message", type = "ByteArray" } } },
              { name = "MessageReceived",
                params = {
                   { name = "NodeID", type = "uint16" },
                   { name = "message", type = "ByteArray" } } },
           }
     } },
   }
}

Radio = {}

function Radio:interface()
   return { send = function(sender, message) self:send(sender, message) end,
            aroundPower = function(node) return self:aroundPower(node) end }
end

function Radio:init(params, interfaces)
   self.scene = interfaces.Scene
   self.TRXs = interfaces.TRX

   self.nodes = {}
   self.links = {}
   self.localChannels = {}

   Simulator.handleEvent{ author = "Scene",
                          event = "nodePowerUp",
                          handler = "newNode" }
   Simulator.handleEvent{ author = "TRX",
                          event = "collision",
                          handler = "cleanLocalChannel" }
   Simulator.handleEvent{ author = "TRX",
                          event = "messageDropped",
                          handler = "cleanLocalChannel" }
   Simulator.handleEvent{ author = "TRX",
                          event = "MessageReceived",
                          handler = "cleanLocalChannel" }
end

function Radio:send(sender, message)
   for i, value in ipairs(self.links[sender]) do
      local listener = i
      local TRX = self.TRXs[i]

      if (TRX.state() ~= "TXON") then
         local rssi = self:rssi(sender, listener)
         table.insert(self.localChannels[listener], message)

         Simulator.postEvent{ author = self,
                              event = "newMessageInChannel",
                              args = { listener, message, rssi } }
      end

   end
end

function Radio:changeLink(node1, node2, rssi, add)
   if(add == true) then
      self.links[node1][node2] = 1
   else
      self.links[node1][node2] = nil
   end

   Simulator.postEvent{ author = self,
                        event = "changeLink",
                        args = { node1, node2, rssi } }
end

function Radio:rssi(sender, listener)
   local dist = self.scene.distance(sender, listener)
   local txpow = self.TRXs[sender].TXPower()

   return txpow + 10 * math.log10(math.pow(0.122 / (4 * math.pi * dist), 2))
end

function Radio:listenTest(node1, node2)
   local rssi21 = self:rssi(node2, node1)
   local TRX1 = self.TRXs[node1]

   if (rssi21 >= TRX1.RXSensivity() and self.links[node1][node2] == nil) then
      self:changeLink(node1, node2, rssi21, true)
   elseif (rssi21 < TRX1.RXSensivity() and self.links[node1][node2] == 1) then
      self:changeLink(node1, node2, rssi21, false)
   end
end

function Radio:listenNodesTest(node1)
   for node2, i in pairs(self.nodes) do
      if (node2 ~= node1) then
         self:listenTest(node1, node2)
         self:listenTest(node2, node1)
      end
   end
end

function Radio:aroundPower(node)
   return (#self.localChannels[node] == 0)
end

function Radio:newNode(node)
   self.links[node] = {}
   self.localChannels[node] = {}

   self:listenNodesTest(node)
   self.nodes[node] = node
end

function Radio:cleanLocalChannel(node)
   self.localChannels[node] = {}
end
