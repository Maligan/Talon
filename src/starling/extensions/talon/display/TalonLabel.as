package starling.extensions.talon.display
{
	import starling.display.BlendMode;
	import starling.events.Event;
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;

	public class TalonLabel extends TextField implements ITalonComponent
	{
		private var _node:Node;

		public function TalonLabel()
		{
			super(0, 0, null);
			_node = new Node();
			_node.addEventListener(Event.CHANGE, onNodeChange);
			_node.addEventListener(Event.RESIZE, onNodeResize);
			_node.width.auto = getTextWidth;
			_node.height.auto = getTextHeight;
		}

		private function getTextWidth():Number
		{
			return textBounds.width;
		}

		private function getTextHeight():Number
		{
			if (text.indexOf("2") != -1)
			{
				trace("get", textBounds.height);
			}

			return textBounds.height;
		}

		private function onNodeChange(e:Event):void
		{
			/**/ if (e.data == "text")      text = _node.getAttribute("text");
			else if (e.data == "halign")    hAlign = _node.getAttribute("halign");
			else if (e.data == "valign")    vAlign = _node.getAttribute("valign");
			else if (e.data == "fontName")  fontName = _node.getAttribute("fontName");
			else if (e.data == "fontColor") color = parseInt(_node.getAttribute("fontColor"));
			else if (e.data == "fontSize")  fontSize = parseInt(_node.getAttribute("fontSize"));
			else if (e.data == "width" || e.data == "height")
			{
				_node.width.isAuto && _node.height.isAuto && (autoSize = TextFieldAutoSize.BOTH_DIRECTIONS);
				_node.width.isAuto && !_node.height.isAuto && (autoSize = TextFieldAutoSize.HORIZONTAL);
				!_node.width.isAuto && _node.height.isAuto && (autoSize = TextFieldAutoSize.VERTICAL);
				!_node.width.isAuto && !_node.height.isAuto && (autoSize = TextFieldAutoSize.NONE);
			}
		}

		private function onNodeResize(e:Event):void
		{
			x = Math.round(_node.bounds.x);
			y = Math.round(_node.bounds.y);
			width = Math.round(_node.bounds.width);
			height = Math.round(_node.bounds.height);

			if (text.indexOf("2") != -1)
			{
				trace("set", height, width);
			}
		}

		public function get node():Node
		{
			return _node;
		}
	}
}