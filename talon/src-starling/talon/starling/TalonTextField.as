package talon.starling
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;

	import talon.Attribute;
	import talon.Node;
	import talon.layout.Layout;
	import talon.utils.ITalonElement;
	import talon.utils.StringUtil;

	public class TalonTextField extends starling.text.TextField implements ITalonElement
	{
		private var _node:Node;
		private var _bridge:DisplayObjectBridge;

		public function TalonTextField()
		{
			super(0, 0, null);

			_node = new Node();
			_node.addListener(Event.RESIZE, onNodeResize);
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
			text = null;
			text = prev;
		}

		protected override function formatText(textField:flash.text.TextField, textFormat:TextFormat):void
		{
			super.formatText(textField, textFormat);
			textField.sharpness = (parseFloat(_node.getAttributeCache(Attribute.FONT_SHARPNESS)) || 0) * 400;
			textField.gridFitType = GridFitType.NONE;
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
			var result:Rectangle = super.getBounds(this);

			// Starling have strange behavior for text with autoSize
			// * ignore halign/valign properties
			// * recalculate mHitArea without after offset (with bitmap font)
			if (getBitmapFont(fontName) != null)
			{
				if (availableWidth == Infinity)
					result.width += textBounds.x;

				if (availableHeight == Infinity)
					result.height += textBounds.y;

				// Add 2px gutter (like native flash)
				// May be this is bad, idea: flash do not provide text padding, but has hardcoded gutter
				// Talon allow add padding.
				//result.inflate(2, 2);
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
			x = Math.round(_node.bounds.x);
			y = Math.round(_node.bounds.y);

			// NB! Up to ceil: bitmap font rendering omit lines with height < lineHeight
			// with float values easy forget this feature
			width = Math.ceil(_node.bounds.width);
			height = Math.ceil(_node.bounds.height);

			_bridge.resize(_node.bounds.width, _node.bounds.height);
		}

		public override function redraw():void
		{
			super.redraw();

			if (numChildren > 0)
			{
				var child:DisplayObject = getChildAt(0);

				// User modified Layout.pad() formula:
				// without parent and child sizes, because starling.text.TextField
				// already arrange text within self bounds.
				// This code only add 'padding' feature.

				var childPaddingLeft:Number = node.padding.left.toPixels(node.ppem, node.ppem, node.ppdp, 0);
				var childPaddingRight:Number = node.padding.right.toPixels(node.ppem, node.ppem, node.ppdp, 0);
				child.x = Layout.pad(0, 0, childPaddingLeft, childPaddingRight, StringUtil.parseAlign(hAlign));

				var childPaddingTop:Number = node.padding.top.toPixels(node.ppem, node.ppem, node.ppdp, 0);
				var childPaddingBottom:Number = node.padding.bottom.toPixels(node.ppem, node.ppem, node.ppdp, 0);
				child.y = Layout.pad(0, 0, childPaddingTop, childPaddingBottom, StringUtil.parseAlign(vAlign));
			}
		}

		//
		// Background customization
		//
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			// Render background
			_bridge.renderBackground(support, parentAlpha * this.alpha);

			// Render glyphs
			super.render(support, parentAlpha);
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(super.getBounds, targetSpace, resultRect);
		}

		public override function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject
		{
			return _bridge.hitTestCustom(super.hitTest, localPoint, forTouch);
		}

		public override function dispose():void
		{
			node.dispose();
			super.dispose();
		}

		//
		// Properties Delegating
		//
		public override function set color(value:uint):void { node.setAttribute(Attribute.FONT_COLOR, StringUtil.toHexRBG(value)) }
		private function onFontColorChange():void { super.color = StringUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }

		public override function set fontSize(value:Number):void { node.setAttribute(Attribute.FONT_SIZE, value.toString()) }
		private function onFontSizeChange():void { super.fontSize = node.ppem }

		public override function set fontName(value:String):void { node && node.setAttribute(Attribute.FONT_NAME, value) || (super.fontName = value) }
		private function onFontNameChange():void { super.fontName = node.getAttributeCache(Attribute.FONT_NAME) || BitmapFont.MINI }

		public override function set hAlign(value:String):void { if (super.hAlign != value) node.setAttribute(Attribute.HALIGN, value) }
		private function onHAlignChange():void { super.hAlign = _node.getAttributeCache(Attribute.HALIGN) }

		public override function set vAlign(value:String):void { if (super.vAlign != value) node.setAttribute(Attribute.VALIGN, value) }
		private function onVAlignChange():void { super.vAlign = _node.getAttributeCache(Attribute.VALIGN) }

		public override function set text(value:String):void { node.setAttribute(Attribute.TEXT, value) }
		private function onTextChange():void { super.text = _node.getAttributeCache(Attribute.TEXT) }

		public override function set autoScale(value:Boolean):void { node.setAttribute(Attribute.AUTO_SCALE, StringUtil.toBoolean(value)); }
		private function onAutoScaleChange():void { super.autoScale = StringUtil.parseBoolean(_node.getAttributeCache(Attribute.AUTO_SCALE)); }

		//
		// Properties
		//
		public function get node():Node
		{
			return _node;
		}

		public override function get autoSize():String { return getAutoSize(node.width.isNone, node.height.isNone); }
		public override function set autoSize(value:String):void
		{
			trace("[TalonTextFiled]", "Ignore autoSize value, this value defined via node width/height == 'none'");
		}

		public override function get border():Boolean { return super.border; }
		public override function set border(value:Boolean):void
		{
			trace("[TalonTextFiled]", "Ignore border value, for debug draw use custom backgroundColor property");
		}
	}
}
