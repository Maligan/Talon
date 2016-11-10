package starling.extensions
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

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
	import talon.utils.ParseUtil;

	public class TalonTextField extends TextField implements ITalonElement
	{
		private static const NATIVE_TEXT_FIELD_PADDING:int = 2;

		private static var _helperRect:Rectangle = new Rectangle();

		private var _node:Node;
		private var _bridge:DisplayObjectBridge;
		private var _requiresRecomposition:Boolean;

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
			_bridge.addAttributeChangeListener(Attribute.FONT_AUTO_SCALE, onAutoScaleChange);
			_bridge.addAttributeChangeListener(Attribute.HALIGN, onHAlignChange, true);
			_bridge.addAttributeChangeListener(Attribute.VALIGN, onVAlignChange, true);
			_bridge.addAttributeChangeListener(Attribute.FONT_NAME, onFontNameChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_COLOR, onFontColorChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_SIZE, onFontSizeChange);
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

			// Add paddings
			result.width  += node.paddingLeft.toPixels(node.ppem, node.ppem, node.ppdp, 0) + node.paddingRight.toPixels(node.ppem, node.ppem, node.ppdp, 0);
			result.height += node.paddingTop.toPixels(node.ppem, node.ppem, node.ppdp, 0)  + node.paddingBottom.toPixels(node.ppem, node.ppem, node.ppdp, 0);

			// Remove native flash / starling hardcoded 2px padding
			result.width -= NATIVE_TEXT_FIELD_PADDING*2;
			result.height -= NATIVE_TEXT_FIELD_PADDING*2;

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

		//
		// DisplayObjectBridge customization
		//
		protected override function setRequiresRecomposition():void
		{
			_requiresRecomposition = true;
			super.setRequiresRecomposition();
		}

		private function recomposeWithPadding():void
		{
			if (numChildren > 0)
			{
				var meshBatch:DisplayObject = getChildAt(0);
				var meshBounds:Rectangle = meshBatch.getBounds(meshBatch);

				// Invoke super.recompose() - via this hack.
				super.getBounds(this, _helperRect);

				// Add horizontal padding
				var paddingLeft:Number = node.paddingLeft.toPixels(node.ppem, node.ppem, node.ppdp, 0);
				var paddingRight:Number = node.paddingRight.toPixels(node.ppem, node.ppem, node.ppdp, 0);

				var isHorizontalAutoSize:Boolean = super.autoSize == TextFieldAutoSize.HORIZONTAL || super.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
				if (isHorizontalAutoSize)
					meshBatch.x += Layout.pad(width, meshBounds.width, paddingLeft - NATIVE_TEXT_FIELD_PADDING, paddingRight - NATIVE_TEXT_FIELD_PADDING, ParseUtil.parseAlign(format.horizontalAlign));
				else
					meshBatch.x += Layout.pad(0, 0, paddingLeft, paddingRight, ParseUtil.parseAlign(format.horizontalAlign));

				// Add vertical padding
				var paddingTop:Number = node.paddingTop.toPixels(node.ppem, node.ppem, node.ppdp, 0);
				var paddingBottom:Number = node.paddingBottom.toPixels(node.ppem, node.ppem, node.ppdp, 0);

				var isVerticalAutoSize:Boolean = super.autoSize == TextFieldAutoSize.VERTICAL || super.autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
				if (isVerticalAutoSize)
					meshBatch.y += Layout.pad(height, meshBounds.height, paddingTop - NATIVE_TEXT_FIELD_PADDING, paddingBottom - NATIVE_TEXT_FIELD_PADDING, ParseUtil.parseAlign(format.verticalAlign));
				else
					meshBatch.y += Layout.pad(0, 0, paddingTop, paddingBottom, ParseUtil.parseAlign(format.verticalAlign));
			}
		}

		public override function render(painter:Painter):void
		{
			// Render background
			_bridge.renderBackground(painter);

			if (_requiresRecomposition)
			{
				_requiresRecomposition = false;
				recomposeWithPadding();
			}

			// In this call recompose() nether will be invoked (already invoked)
			// and now this is analog of super.super.render() :-)
			super.render(painter);
		}

		public override function hitTest(localPoint:Point):DisplayObject
		{
			return getBounds(this, _helperRect).containsPoint(localPoint) ? this : null;
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(null, targetSpace, resultRect);
		}

		public override function dispose():void
		{
			node.dispose();
			super.dispose();
		}

		//
		// Properties Delegating
		//

		// TODO: sharpness, gridFitType
		private function onFontColorChange():void { format.color = ParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }
		private function onFontSizeChange():void { format.size = node.ppem }
		private function onFontNameChange():void { format.font = node.getAttributeCache(Attribute.FONT_NAME) || BitmapFont.MINI; }
		private function onHAlignChange():void { format.horizontalAlign = _node.getAttributeCache(Attribute.HALIGN) }
		private function onVAlignChange():void { format.verticalAlign = _node.getAttributeCache(Attribute.VALIGN) }
		private function onTextChange():void { super.text = _node.getAttributeCache(Attribute.TEXT); node.invalidate(); } // TODO: What about invalidate()?
		private function onAutoScaleChange():void { super.autoScale = ParseUtil.parseBoolean(_node.getAttributeCache(Attribute.FONT_AUTO_SCALE)); }

		//
		// Properties
		//
		public function get node():Node { return _node; }

		public override function set text(value:String):void { node.setAttribute(Attribute.TEXT, value) }
		public override function set autoScale(value:Boolean):void { node.setAttribute(Attribute.FONT_AUTO_SCALE, value.toString()); }

		public override function get autoSize():String { return getAutoSize(node.width.isNone, node.height.isNone); }
		public override function set autoSize(value:String):void { trace("[TalonTextFiled]", "Ignore autoSize value, this value defined via node width/height == 'none'"); }

		public override function get border():Boolean { return false; }
		public override function set border(value:Boolean):void { trace("[TalonTextFiled]", "Ignore border value, for debug draw use custom backgroundColor property"); }
	}
}
