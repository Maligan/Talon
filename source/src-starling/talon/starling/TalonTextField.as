package talon.starling
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;

	import talon.Attribute;
	import talon.Node;
	import talon.layout.Layout;
	import talon.utils.ITalonElement;
	import talon.utils.StringParseUtil;

	public class TalonTextField extends starling.text.TextField implements ITalonElement
	{
		private var _node:Node;
		private var _bridge:DisplayObjectBridge;

		public function TalonTextField()
		{
			super(0, 0, null);

			_node = new Node();
			_node.addTriggerListener(Event.RESIZE, onNodeResize);
			_node.width.auto = measureWidth;
			_node.height.auto = measureHeight;

			// Bridge
			_bridge = new DisplayObjectBridge(this, node);
			_bridge.addAttributeChangeListener(Attribute.TEXT, onTextChange);
			_bridge.addAttributeChangeListener(Attribute.AUTO_SCALE, onAutoScaleChange);
			_bridge.addAttributeChangeListener(Attribute.HALIGN, onHAlignChange);
			_bridge.addAttributeChangeListener(Attribute.VALIGN, onVAlignChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_NAME, onFontNameChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_COLOR, onFontColorChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_SIZE, onFontSizeChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_SHARPNESS, onSharpnessChange);
		}

		private function onSharpnessChange():void
		{
			var prev:String = text;
			// Use super.text to save attribute value
            super.text = null;
            super.text = prev;
		}

		//
		// Measure size
		//
		private function measureWidth(availableHeight:Number):Number { return measure(Infinity, availableHeight).width; }
		private function measureHeight(availableWidth:Number):Number { return measure(availableWidth, Infinity).height; }

		private function measure(availableWidth:Number, availableHeight:Number):Rectangle
		{
			super.autoSize = getAutoSize(availableWidth == Infinity, availableHeight == Infinity);
			super.width = availableWidth;
			super.height = availableHeight;

			// NB! Use super.getBounds()
			var result:Rectangle = super.getBounds(this);

			// Starling have strange behavior for text with autoSize
			// * ignore halign/valign properties
			// * recalculate mHitArea without after offset (with bitmap font)
			if (getBitmapFont(format.font) != null)
			{
				if (availableWidth == Infinity)
					result.width += textBounds.x;

				if (availableHeight == Infinity)
					result.height += textBounds.y;
			}

			// Add paddings
			result.width  += node.padding.left.toPixels(node.ppem, node.ppem, node.ppdp, 0) + node.padding.right.toPixels(node.ppem, node.ppem, node.ppdp, 0);
			result.height += node.padding.top.toPixels(node.ppem, node.ppem, node.ppdp, 0)  + node.padding.bottom.toPixels(node.ppem, node.ppem, node.ppdp, 0);

			super.autoSize = TextFieldAutoSize.NONE;
			return result;
		}

		private function getAutoSize(autoWidth:Boolean, autoHeight:Boolean):String
		{
			/**/ if ( autoWidth &&  autoHeight) return TextFieldAutoSize.BOTH_DIRECTIONS;
			else if ( autoWidth && !autoHeight) return TextFieldAutoSize.HORIZONTAL;
			else if (!autoWidth &&  autoHeight) return TextFieldAutoSize.VERTICAL;
			return TextFieldAutoSize.NONE;
		}

		private function onNodeResize():void
		{
			x = _node.bounds.x;
			y = _node.bounds.y;
			width = _node.bounds.width;
			height = _node.bounds.height;
		}

		// FIXME: Реализовать
		public function redraw():void
		{
			if (numChildren > 0)
			{
                // NB! Used first children (border is DISABLED)
				var child:DisplayObject = getChildAt(0);

				// User modified Layout.pad() formula:
				// without parent and child sizes, because starling.text.TextField
				// already arrange text within self bounds.
				// This code only add 'padding' distance.

				var childPaddingLeft:Number = node.padding.left.toPixels(node.ppem, node.ppem, node.ppdp, 0);
				var childPaddingRight:Number = node.padding.right.toPixels(node.ppem, node.ppem, node.ppdp, 0);
//				child.x = Layout.pad(0, 0, childPaddingLeft, childPaddingRight, StringParseUtil.parseAlign(hAlign));

				var childPaddingTop:Number = node.padding.top.toPixels(node.ppem, node.ppem, node.ppdp, 0);
				var childPaddingBottom:Number = node.padding.bottom.toPixels(node.ppem, node.ppem, node.ppdp, 0);
//				child.y = Layout.pad(0, 0, childPaddingTop, childPaddingBottom, StringParseUtil.parseAlign(vAlign));
			}
		}

		//
		// Background customization
		//
		public override function render(painter:Painter):void
		{
			// Render background
			_bridge.renderBackground(painter);

			// Render glyphs
			super.render(painter);
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(super.getBounds, targetSpace, resultRect);
		}

		public override function dispose():void
		{
			node.dispose();
			super.dispose();
		}

		//
		// Properties Delegating
		//

		// FIXME: Обратные изменения от TextFormat в узел
		// Вынести sharpness, gridFitType
		private function onFontColorChange():void { format.color = StringParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }
		private function onFontSizeChange():void { format.size = node.ppem }
		private function onFontNameChange():void { format.font = node.getAttributeCache(Attribute.FONT_NAME) || BitmapFont.MINI }
		private function onHAlignChange():void { format.horizontalAlign = _node.getAttributeCache(Attribute.HALIGN) }
		private function onVAlignChange():void { format.verticalAlign = _node.getAttributeCache(Attribute.VALIGN) }

		private function onTextChange():void { super.text = _node.getAttributeCache(Attribute.TEXT); }
		private function onAutoScaleChange():void { super.autoScale = StringParseUtil.parseBoolean(_node.getAttributeCache(Attribute.AUTO_SCALE)); }


		//
		// Properties
		//
		public function get node():Node
		{
			return _node;
		}

		public override function set text(value:String):void { node.setAttribute(Attribute.TEXT, value) }
		public override function set autoScale(value:Boolean):void { node.setAttribute(Attribute.AUTO_SCALE, value.toString()); }

		public override function get autoSize():String { return getAutoSize(node.width.isNone, node.height.isNone); }
		public override function set autoSize(value:String):void
		{
			trace("[TalonTextFiled]", "Ignore autoSize value, this value defined via node width/height == 'none'");
		}

		public override function get border():Boolean { return false; }
		public override function set border(value:Boolean):void
		{
			trace("[TalonTextFiled]", "Ignore border value, for debug draw use custom backgroundColor property");
		}
	}
}
