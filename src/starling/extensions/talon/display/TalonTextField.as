package starling.extensions.talon.display
{
	import flash.filters.DropShadowFilter;

	import starling.events.Event;
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.parseColor;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;

	public class TalonTextField extends TextField implements ITalonTarget
	{
		private var _node:Node;

		public function TalonTextField()
		{
			super(0, 0, null);

			_node = new Node();
			_node.addEventListener(Event.CHANGE, onNodeChange);
			_node.addEventListener(Event.RESIZE, onNodeResize);
			_node.width.auto = _node.minWidth.auto = _node.maxWidth.auto = getTextWidth;
			_node.height.auto = _node.minHeight.auto = _node.maxHeight.auto = getTextHeight;

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
			x = Math.round(_node.bounds.x) - 2;
			y = Math.round(_node.bounds.y) - 2;
			width = Math.round(_node.bounds.width) - 2;
			height = Math.round(_node.bounds.height) - 2;
		}

		public function get node():Node
		{
			return _node;
		}
	}
}