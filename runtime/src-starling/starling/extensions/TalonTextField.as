package starling.extensions
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Mesh;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.styles.DistanceFieldStyle;
	import starling.text.BitmapChar;
	import starling.text.BitmapFont;
	import starling.text.ITextCompositor;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.core.Style;
	import talon.layouts.Layout;
	import talon.utils.Gauge;
	import talon.utils.ParseUtil;

	/** starling.display.TextField which implements ITalonDisplayObject. */
	public class TalonTextField extends TextField implements ITalonDisplayObject
	{
		// There are 2px padding & 1px flash.text.TextField bug with autoSize disharmony
		private static const TRUE_TYPE_CORRECTION:int = 4 + 1;

		private static var sRect:Rectangle = new Rectangle();
		private static var _sPoint:Point = new Point();

		private var _bridge:TalonDisplayObjectBridge;
		private var _requiresRecomposition:Boolean;
		private var _requiresPadding:Boolean;
		private var _textBounds:Rectangle;
		private var _lastBounds:Rectangle;
		
		/** @private */
		public function TalonTextField()
		{
			super(0, 0, null);

			_textBounds = new Rectangle();
			_lastBounds = new Rectangle();

			// Bridge
			_bridge = new TalonDisplayObjectBridge(this);
			_bridge.setAttributeChangeListener(Attribute.TEXT, onTextChange);
			_bridge.setAttributeChangeListener(Attribute.WRAP, onWrapChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_AUTO_SCALE, onAutoScaleChange);
			_bridge.setAttributeChangeListener(Attribute.ALIGN_X, onHAlignChange, true);
			_bridge.setAttributeChangeListener(Attribute.ALIGN_Y, onVAlignChange, true);
			_bridge.setAttributeChangeListener(Attribute.FONT_NAME, onFontNameChange, true);
			_bridge.setAttributeChangeListener(Attribute.INTERLINE, onInterlineChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_COLOR, onFontColorChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_SIZE, onFontSizeChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_EFFECT, onFontEffectChange);

			node.getOrCreateAttribute(Attribute.WRAP).inited = "true"; // FIXME: Bad Ya?
			node.addListener(Event.ADDED, onNodeParentChange);
			node.addListener(Event.REMOVED, onNodeParentChange);
			node.width.auto = measureWidth;
			node.height.auto = measureHeight;

			batchable = true; // TODO: Allow setup batchable flag
		}

		//
		// Measure size
		//
		private function measureWidth(height:Number):Number { return measure(Infinity, height).width; }
		private function measureHeight(width:Number):Number { return measure(width, Infinity).height; }
		private function measure(width:Number, height:Number):Rectangle
		{
			setBounds(width, height);
			recompose();

			sRect.copyFrom(_textBounds);
			sRect.width  += node.paddingLeft.toPixels() + node.paddingRight.toPixels();
			sRect.height += node.paddingTop.toPixels() + node.paddingBottom.toPixels();
			
			return sRect;
		}

		/** This text bounds respect font lineHeight and it height can be only (lineHeight*scale * N). */
		private function getTrueTextBounds(out:Rectangle = null):Rectangle
		{
			out ||= new Rectangle();
			out.setEmpty();

			// For TrueType fonts
			var mesh:Mesh = getChildAt(0) as Mesh;
			var font:BitmapFont = getCompositor(format.font) as BitmapFont;
			if (font == null)
			{
				mesh.getBounds(this, out);
				out.inflate(-2, -2);
				return out;
			}

			// For empty text field
			var scale:Number = format.size / font.size;
			var numDrawableChars:int = mesh.numVertices / 4;
			if (numDrawableChars == 0)
			{
				out.setTo(0, 0, 0, font.lineHeight * scale);
				return out;
			}

			if (autoScale) scale = NaN;

			// find anchor chars
			var leftmostCharLeft:Number = NaN;
			var rightmostCharRight:Number = NaN;
			var bottommostCharTop:Number = NaN;
			var topmostCharTop:Number = NaN;

			var numNonDrawableChars:int = 0;

			for (var i:int = 0; i < text.length; i++)
			{
				var charID:int = text.charCodeAt(i);
				var char:BitmapChar = font.getChar(charID);
				var charQuadIndex:int = i - numNonDrawableChars;
				if (charQuadIndex >= numDrawableChars) break;

				var charIsDrawable:Boolean = char != null && (char.width != 0 && char.height != 0);
				if (charIsDrawable)
				{
					if (scale != scale)
					{
						var quadHeight:Number = mesh.getVertexPosition(charQuadIndex*4 + 3, _sPoint).y
											  - mesh.getVertexPosition(charQuadIndex*4 + 0, _sPoint).y;

						scale = quadHeight / char.height;
					}

					var charLeft:Number = mesh.getVertexPosition(charQuadIndex*4 + 0, _sPoint).x - char.xOffset*scale;
					if (charLeft < leftmostCharLeft || leftmostCharLeft != leftmostCharLeft)
						leftmostCharLeft = charLeft;

					var charRight:Number = mesh.getVertexPosition(charQuadIndex*4 + 1, _sPoint).x;
					if (charRight > rightmostCharRight || rightmostCharRight != rightmostCharRight)
						rightmostCharRight = charRight;

					var charTop:Number = _sPoint.y - char.yOffset*scale;
					if (charTop > bottommostCharTop || bottommostCharTop != bottommostCharTop)
						bottommostCharTop = charTop;

					if (charTop < topmostCharTop || topmostCharTop != topmostCharTop)
						topmostCharTop = charTop;
				}
				else
					numNonDrawableChars++;
			}

			// find width & height

			var lineHeight:Number = font.lineHeight*scale;
			var leading:Number = format.leading*scale;

			var numLines:int = 1 + int((bottommostCharTop-topmostCharTop) / (lineHeight+leading));
			var width:Number = rightmostCharRight - leftmostCharLeft;
			var height:Number = numLines*lineHeight + (numLines-1)*leading;

			out.setTo(leftmostCharLeft, topmostCharTop, width, height);
			
			// BitmapFont#arrangeChars has floating point error:
			// If TextField used some combination of font, size and text
			// containerWidth & containerHeight have small delta.
			// Ceiling used for compensate those errors
			out.width  = Math.ceil(out.width);
			out.height = Math.ceil(out.height);
			return out;
		}

		private function onNodeParentChange():void
		{
			var unit:String = node.fontSize.unit;
			if (unit == Gauge.EM || unit == Gauge.PERCENT || node.getOrCreateAttribute(Attribute.FONT_SIZE).isInherit)
				onFontSizeChange();
		}
		
		//
		// TalonDisplayObjectBridge customization
		//
		/** @private */
		public override function setRequiresRecomposition():void
		{
			_requiresRecomposition = true;
			super.setRequiresRecomposition();
		}

		/** @private */
		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(refreshAndRender, painter);
		}

		private function refreshAndRender(painter:Painter):void
		{
			refresh();

			// In this call recompose() nether will be invoked (already invoked)
			// and now this is analog of super.super.render() :-)
			super.render(painter);
		}
		
		private function refresh():void
		{
			setBounds(node.bounds.width, node.bounds.height);
			recompose();
			repadding();
		}

		private function recompose():void
		{
			if (_requiresRecomposition)
			{
				// Call super.recompose()
				super.getBounds(this, sRect);

				getTrueTextBounds(_textBounds);

				_requiresPadding = true;
				_requiresRecomposition = false;
			}
		}

		private function repadding():void
		{
			if (_requiresPadding)
			{
				_requiresPadding = false;

				var halign:Number = ParseUtil.parseAlign(format.horizontalAlign);
				var valign:Number = ParseUtil.parseAlign(format.verticalAlign);
				var mesh:DisplayObject = getChildAt(0);

				var paddingTop:Number = node.paddingTop.toPixels();
				var paddingRight:Number = node.paddingRight.toPixels();
				var paddingBottom:Number = node.paddingBottom.toPixels();
				var paddingLeft:Number = node.paddingLeft.toPixels();

				mesh.x = Layout.pad(node.bounds.width, _textBounds.width, paddingLeft, paddingRight, halign) - _textBounds.x;
				mesh.y = Layout.pad(node.bounds.height, _textBounds.height, paddingTop, paddingBottom, valign) - _textBounds.y;
			}
		}

		/** @private */
		public override function hitTest(localPoint:Point):DisplayObject
		{
			if (!visible || !touchable) return null;
			if (mask && !hitTestMask(localPoint)) return null;
			return getBounds(this, sRect).containsPoint(localPoint) ? this : null;
		}

		/** @private */
		public override function get textBounds():Rectangle
		{
			refresh(); // TODO: Add validation!
			return _textBounds;
		}

		/** @private */
		public override function dispose():void
		{
			_bridge.dispose();
			super.dispose();
		}
		
		//
		// Font Effect
		//
		private function onFontEffectChange():void
		{
			var compositor:ITextCompositor = getCompositor(format.font);
			if (compositor == null) {
				return;
			}
			
			var dfs:DistanceFieldStyle = compositor.getDefaultMeshStyle(style, format, options) as DistanceFieldStyle;
			if (dfs == null) {
				return;
			}

			var value:String = node.getAttributeCache(Attribute.FONT_EFFECT);
			var func:Array = ParseUtil.parseFunction(value);
			if (func == null)
				dfs.setupBasic();
			else if (func[0] == "shadow")
			{
				var x:Number = ParseUtil.parseNumber(func[1], 2);
				var y:Number = ParseUtil.parseNumber(func[2], x);
				
				if (x != 0 || y != 0)
					dfs.setupDropShadow(
						ParseUtil.parseNumber(func[3], 0.2), // blur
						x,	 								 // x
						y,	 								 // y
						ParseUtil.parseColor(func[4], 0x0),	 // color
						ParseUtil.parseNumber(func[5], 0.5)	 // alpha	
					);
				else
					dfs.setupGlow(
						ParseUtil.parseNumber(func[3], 0.2),
						ParseUtil.parseColor(func[4], 0x0),	 // color
						ParseUtil.parseNumber(func[5], 0.5)	 // alpha	
					);
			}
			else if (func[0] == "stroke")
				dfs.setupOutline(
					ParseUtil.parseNumber(func[1], 0.25), // width
					ParseUtil.parseColor(func[2], 0x0),	  // color
					ParseUtil.parseNumber(func[3], 1.0)	  // alpha
				)
		}
		
		//
		// Bounds override
		//

		/** @private */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(null, targetSpace, resultRect);
		}
		
		private function setBounds(width:Number, height:Number):void
		{
			// Crop padding
			var trueTypeCorrection:int = getCompositor(format.font) ? 0 : TRUE_TYPE_CORRECTION;
			width = width - node.paddingRight.toPixels() - node.paddingLeft.toPixels() + trueTypeCorrection;
			height = height - node.paddingTop.toPixels() - node.paddingBottom.toPixels() + trueTypeCorrection;

			// Change super values with without excess setRequiresRecomposition() calls
			if (_lastBounds.width != width && _textBounds.width != width)
				super.width = _lastBounds.width = width;
				
			if (_lastBounds.height != height && _textBounds.height != height)
				super.height = _lastBounds.height = height;
		}

		//
		// Properties Delegating
		//

		private function onFontColorChange():void { format.color = ParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }
		private function onFontSizeChange():void { format.size = node.metrics.ppem; node.invalidate(); }
		private function onFontNameChange():void { format.font = node.getAttributeCache(Attribute.FONT_NAME); node.invalidate(); onFontEffectChange(); }
		private function onHAlignChange():void { format.horizontalAlign = node.getAttributeCache(Attribute.ALIGN_X) }
		private function onVAlignChange():void { format.verticalAlign = node.getAttributeCache(Attribute.ALIGN_Y) }
		private function onAutoScaleChange():void { super.autoScale = ParseUtil.parseBoolean(node.getAttributeCache(Attribute.FONT_AUTO_SCALE)); }
		private function onWrapChange():void { super.wordWrap = ParseUtil.parseBoolean(node.getAttributeCache(Attribute.WRAP)); node.invalidate(); }
		private function onInterlineChange():void { format.leading = Gauge.toPixels(node.getAttributeCache(Attribute.INTERLINE), node.metrics); node.invalidate(); }
		private function onTextChange():void { super.text = node.getAttributeCache(Attribute.TEXT); node.invalidate(); }
		
		//
		// ITalonDisplayObject
		//
		/** @private */
		public function get node():Node { return _bridge.node; }
		public function get rectangle():Rectangle { return node.bounds; }

		public function query(selector:String = null):TalonQuery { return new TalonQuery(this).select(selector); }
		
		public function setAttribute(name:String, value:String):void { node.setAttribute(name, value); }
		public function getAttribute(name:String):String { return node.getOrCreateAttribute(name).value; }
		public function setStyles(styles:Vector.<Style>):void { node.setStyles(styles); }
		public function setResources(resources:Object):void { node.setResources(resources); }
		
		//
		// Properties override
		//
		
		/** @private */ public override function set wordWrap(value:Boolean):void {  node.setAttribute(Attribute.WRAP, value.toString()); }
		/** @private */ public override function set text(value:String):void { node.setAttribute(Attribute.TEXT, value) }
		/** @private */ public override function set autoScale(value:Boolean):void { node.setAttribute(Attribute.FONT_AUTO_SCALE, value.toString()); }

		/** @private */ public override function get autoSize():String { return getAutoSize(node.width.isNone, node.height.isNone); }
		/** @private */ public override function set autoSize(value:String):void { trace("[TalonTextFiled]", "Ignore autoSize value, this value defined via node width/height == 'none'"); }

		private function getAutoSize(autoWidth:Boolean, autoHeight:Boolean):String
		{
			/**/ if ( autoWidth &&  autoHeight) return TextFieldAutoSize.BOTH_DIRECTIONS;
			else if ( autoWidth && !autoHeight) return TextFieldAutoSize.HORIZONTAL;
			else if (!autoWidth &&  autoHeight) return TextFieldAutoSize.VERTICAL;
			return TextFieldAutoSize.NONE;
		}
		
		/** @private */ public override function get border():Boolean { return false; }
		/** @private */ public override function set border(value:Boolean):void { trace("[TalonTextFiled]", "Ignore border value, for debug draw use custom 'fill' property"); }
	}
}
