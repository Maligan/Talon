package starling.extensions.talon.display
{
	import starling.events.Event;
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.parseColor;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;

	public class TalonLabel extends TextField implements ITalonTarget
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

			touchable = false;
		}

		private function getTextWidth():Number
		{
			return textBounds.width;
		}

		private function getTextHeight():Number
		{
			return textBounds.height;
		}

		private function onNodeChange(e:Event):void
		{
			/**/ if (e.data == "text")      text = _node.getAttribute("text");
			else if (e.data == "halign")    hAlign = _node.getAttribute("halign");
			else if (e.data == "valign")    vAlign = _node.getAttribute("valign");
			else if (e.data == "fontName")  fontName = _node.getAttribute("fontName") || BitmapFont.MINI;
			else if (e.data == "fontColor") color = parseColor(_node.getAttribute("fontColor"));
			else if (e.data == "fontSize")  fontSize = node.ppem;
			else if (e.data == "width" || e.data == "height")
			{
				var isHorizontal:Boolean = _node.width.isAuto;
				var isVertical:Boolean = _node.height.isAuto;

				/**/ if ( isHorizontal &&  isVertical) (autoSize = TextFieldAutoSize.BOTH_DIRECTIONS);
				else if ( isHorizontal && !isVertical) (autoSize = TextFieldAutoSize.HORIZONTAL);
				else if (!isHorizontal &&  isVertical) (autoSize = TextFieldAutoSize.VERTICAL);
				else if (!isHorizontal && !isVertical) (autoSize = TextFieldAutoSize.NONE);
			}
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