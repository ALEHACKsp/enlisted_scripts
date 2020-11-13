options remove_unused_symbols = false
module walker_node
require game.es.ai.walker_common
require DagorDataBlock
require BehNodes
require EnlistedBehNodes

class BehNodeAdapter
  thisNode : BehNode?
  owner : BehaviourTree?
  def abstract loadFromBlk(var data : DataBlock) : void
  def abstract init() : void
  def abstract update(dt : float) : EBehResult
  def abstract drawDebug(children : bool) : void
  def abstract reset() : void
