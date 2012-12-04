declare_module{
   name = "Radio",
   author = "Alexander Yarygin",
   type = "environment",
   description = "",
   params = { },
   interface = {
      functions = {},
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
        interface = { } },
      { name = "TRX", type = "hardware",
        interface = { } },
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
   Simulator.handleEvent{ event = "collision",
                          handler = "cleanLocalChannel"}
   Simulator.handleEvent{ event = "messageDropped",
                          handler = "cleanLocalChannel"}
   Simulator.handleEvent{ event = "MessageReceived",
                          handler = "cleanLocalChannel"}
end

function Radio:send(sender, message)
   for i = 0, #self.links[sender] do
      local listener = self.links[sender][i]
      local TRX = self.TRXs[listener]

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
