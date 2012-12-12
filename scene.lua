declare_module{
   name = "Scene",
   author = "Alexander Yarygin",
   type = "environment",
   description = "Двухмерная сцена",
   params = {
      { name = "xSize", type = "double", info = "размер среды по оси X", default = 100.0 },
      { name = "ySize", type = "double", info = "размер среды по оси Y", default = 100.0 },
      { name = "nodes", type = "nodes" },
      { name = "coords", type = "table",
        args = { columns = "3", columnName1 = "NodeID", columnName2 = "X", columnName3 = "Y" } }
   },
   interface = {
      functions = {
         { name = "coord", info = "Возвращает координату узла", resultType = "double[2]",
           args = {
              { name = "NodeID", type = "uint16" } } },
         { name = "distance", info = "возвращает расстояние между двуми узлами",
           args = {
              { name = "NodeID1", type = "uint16" },
              { name = "NodeID2", type = "uint16" } } }
      },
      events = {
         { name = "nodePowerUp",
           info = "Включение узла",
           params = { { name = "NodeID", type = "uint16" },
                      { name = "coordx", type = "double" },
                      { name = "coordy", type = "double" } } }
      }
   }
}

Scene = { }

function Scene:interface()
   return { coord = function(Node) return self:coord(Node) end,
            distance = function(Node1, Node2) return self:distance(Node1, Node2) end }
end

function Scene:init(params, interfaces)
   self.size = { params.xSize, params.ySize }
   self.nodes = params.nodes
   self.coords = params.coords

   for nodeID,coord in pairs(self.coords) do
      Simulator.postEvent{ author = self,
                           event = "nodePowerUp",
                           delay = nodeID * 100,
                           args = { nodeID, coord[1], coord[2] } }
   end

end

function Scene:coord(Node)
   return self.coords[Node]
end

function Scene:distance(Node1, Node2)
   print(Node1, Node2)
   local coord1 = self.coords[Node1]
   local coord2 = self.coords[Node2]

   local dist = math.sqrt(math.pow((coord2[1] - coord1[1]), 2)
                       + (math.pow((coord2[2] - coord1[2]), 2)))

   return dist
end