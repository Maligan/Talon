package talon.starling
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
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

			// TextField autoSize
			_node.width.auto = _node.minWidth.auto = _node.maxWidth.auto = measureWidth;
			_node.height.auto = _node.minHeight.auto = _node.maxHeight.auto = measureHeight;
			autoSize = TextFieldAutoSize.NONE;
			batchable = true;
			border = true;

			// Bridge
			_bridge = new DisplayObjectBridge(this, node);
			_bridge.addAttributeChangeListener(Attribute.TEXT, onTextChange);
			_bridge.addAttributeChangeListener(Attribute.HALIGN, onHAlignChange);
			_bridge.addAttributeChangeListener(Attribute.VALIGN, onVAlignChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_NAME, onFontNameChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_COLOR, onFontColorChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_SIZE, onFontSizeChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_SHARPNESS, onSharpnessChange);
		}

		private function onSharpnessChange():void
		{
			var oldText:String = text;
			text = "0";
			text = oldText;
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
		private function measureWidth(availableWidth:Number, availableHeight:Number):Number { return measure(availableWidth, availableHeight).width; }
		private function measureHeight(availableWidth:Number, availableHeight:Number):Number { return measure(availableWidth, availableHeight).height; }

		/** TODO: Optimize. */
		private function measure(aw:Number, ah:Number):Rectangle
		{
			autoSize = getAutoSize(node.width.isAuto, node.height.isAuto);
			if (aw != Infinity) width = aw;
			if (ah != Infinity) height = ah;
			var result:Rectangle = textBounds;
			result.inflate((2 + 5)/2 , (2 + 4)/2); // starling remove flash 2px offset
			return result;
		}

		private function getAutoSize(width:Boolean, height:Boolean):String
		{
			/**/ if ( width &&  height) return TextFieldAutoSize.BOTH_DIRECTIONS;
			else if ( width && !height) return TextFieldAutoSize.VERTICAL;
			else if (!width &&  height) return TextFieldAutoSize.HORIZONTAL;
			return TextFieldAutoSize.NONE;
		}

		//
		// Resize
		//
		private function onNodeResize():void
		{
			autoSize = TextFieldAutoSize.NONE;

			x = Math.round(_node.bounds.x);
			y = Math.round(_node.bounds.y);
			width = Math.round(_node.bounds.width);
			height = Math.round(_node.bounds.height);

			_bridge.resize(_node.bounds.width, _node.bounds.height);

			text = text;
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
		// Properties Overrides
		//
		public override function set color(value:uint):void { node.setAttribute(Attribute.FONT_COLOR, StringUtil.toHexRBG(value)) }
		private function onFontColorChange():void { super.color = StringUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }

		public override function set fontSize(value:Number):void { node.setAttribute(Attribute.FONT_SIZE, value.toString()) }
		private function onFontSizeChange():void { super.fontSize = node.ppem }

		public override function set fontName(value:String):void { node && node.setAttribute(Attribute.FONT_NAME, value) || (super.fontName = value) }
		private function onFontNameChange():void { super.fontName = node.getAttributeCache(Attribute.FONT_NAME) || BitmapFont.MINI }

		public override function set hAlign(value:String):void { if (super.hAlign != value) node.setAttribute(Attribute.HALIGN, value) }
		private function onHAlignChange():void { super.hAlign = _node.getAttributeCache(Attribute.HALIGN); }

		public override function set vAlign(value:String):void { if (super.vAlign != value) node.setAttribute(Attribute.VALIGN, value) }
		private function onVAlignChange():void { super.vAlign = _node.getAttributeCache(Attribute.VALIGN); }

		public override function set text(value:String):void { node.setAttribute(Attribute.TEXT, value) }
		private function onTextChange():void { super.text = _node.getAttributeCache(Attribute.TEXT).replace("!", "\n"); }

		//
		// Properties
		//
		public function get node():Node
		{
			return _node;
		}
	}
}