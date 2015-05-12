package talon.starling
{

	import starling.core.RenderSupport;
	import starling.events.Event;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.ITalonElement;
	import talon.utils.StringUtil;

	public class TalonTextField extends TextField implements ITalonElement
	{
		private var _node:Node;
		private var _bridge:DisplayObjectBridge;

		public function TalonTextField()
		{
			super(0, 0, null);

			_node = new Node();
			_node.addEventListener(Event.CHANGE, onNodeChange);
			_node.addEventListener(Event.RESIZE, onNodeResize);

			_bridge = new DisplayObjectBridge(this, node);

			// TextField autoSize
			_node.width.auto = _node.minWidth.auto = _node.maxWidth.auto = getTextWidth;
			_node.height.auto = _node.minHeight.auto = _node.maxHeight.auto = getTextHeight;
			autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
		}

		private function getTextWidth(availableWidth:Number, availableHeight:Number):Number
		{
			adjust(availableWidth, availableHeight);
			return textBounds.width;
		}

		private function getTextHeight(availableWidth:Number, availableHeight:Number):Number
		{
			adjust(availableWidth, availableHeight);
			return textBounds.height;
		}

		private function adjust(aw:Number, ah:Number):void
		{
			/**/ if (aw == Infinity && ah == Infinity) autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
			else if (aw == Infinity && ah != Infinity) autoSize = TextFieldAutoSize.VERTICAL;
			else if (aw != Infinity && ah == Infinity) autoSize = TextFieldAutoSize.HORIZONTAL;
			else if (aw != Infinity && ah != Infinity) autoSize = TextFieldAutoSize.NONE;

			if (aw != Infinity) width = aw;
			if (ah != Infinity) height = ah;
		}

		private function onNodeChange(e:Event):void
		{
			/**/ if (e.data == Attribute.TEXT)         text = _node.getAttribute(Attribute.TEXT);
			else if (e.data == Attribute.HALIGN)       hAlign = _node.getAttribute(Attribute.HALIGN);
			else if (e.data == Attribute.VALIGN)       vAlign = _node.getAttribute(Attribute.VALIGN);
			else if (e.data == Attribute.FONT_NAME)
						fontName = 'Helvet'//_node.getAttribute(Attribute.FONT_NAME) || BitmapFont.MINI;
			else if (e.data == Attribute.FONT_COLOR)   color = StringUtil.parseColor(_node.getAttribute(Attribute.FONT_COLOR));
			else if (e.data == Attribute.FONT_SIZE)    fontSize = node.ppem;
		}

		private function onNodeResize(e:Event):void
		{
			x = Math.round(_node.bounds.x)// - 2;
			y = Math.round(_node.bounds.y)// - 2;
			width = Math.round(_node.bounds.width)// - 2;
			height = Math.round(_node.bounds.height)// - 2;

			_bridge.resize(width, height);

			autoSize = TextFieldAutoSize.NONE;
		}

		public function get node():Node
		{
			return _node;
		}

		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			// Render background
			_bridge.renderBackground(support, parentAlpha);

			// Render glyphs
			super.render(support, parentAlpha);
		}
	}
}