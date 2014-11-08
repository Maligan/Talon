package starling.extensions.talon.display
{
	import starling.events.Event;
	import starling.extensions.talon.core.Node;
	import starling.text.TextField;

	public class TalonLabel extends TextField implements ITalonComponent
	{
		private var _node:Node;

		public function TalonLabel()
		{
			super(0, 0, "");
			_node = new Node();
			_node.addEventListener(Event.CHANGE, onNodeChange);
			_node.addEventListener(Event.RESIZE, onNodeResize);
		}

		private function onNodeChange(e:Event):void
		{
			if (e.data == "text") text = _node.getAttribute("text");
		}

		private function onNodeResize(e:Event):void
		{
			x = Math.round(_node.bounds.x);
			y = Math.round(_node.bounds.y);
			width = Math.round(_node.bounds.width);
			height = Math.round(_node.bounds.height);
		}

		public function get node():Node
		{
			return _node;
		}
	}
}