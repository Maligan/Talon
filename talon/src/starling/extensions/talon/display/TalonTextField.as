package starling.extensions.talon.display
{

	import starling.events.Event;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Attributes;
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

			// TextField autoSize
			_node.width.auto = _node.minWidth.auto = _node.maxWidth.auto = getTextWidth;
			_node.height.auto = _node.minHeight.auto = _node.maxHeight.auto = getTextHeight;
			autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;

			touchable = false;
		}

		private function getTextWidth(width:Number, height:Number):Number
		{
			return textBounds.width;
		}

		private function getTextHeight(width:Number, height:Number):Number
		{
			return textBounds.height;
		}

		private function onNodeChange(e:Event):void
		{
			/**/ if (e.data == Attributes.TEXT)         text = _node.getAttribute(Attributes.TEXT);
			else if (e.data == Attributes.HALIGN)       hAlign = _node.getAttribute(Attributes.HALIGN);
			else if (e.data == Attributes.VALIGN)       vAlign = _node.getAttribute(Attributes.VALIGN);
			else if (e.data == Attributes.FONT_NAME)    fontName = _node.getAttribute(Attributes.FONT_NAME) || BitmapFont.MINI;
			else if (e.data == Attributes.FONT_COLOR)   color = parseColor(_node.getAttribute(Attributes.FONT_COLOR));
			else if (e.data == Attributes.FONT_SIZE)    fontSize = node.ppem;
			else if (e.data == Attributes.WIDTH || e.data == Attributes.HEIGHT)
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