package starling.extensions
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Mesh;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.text.BitmapChar;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.layouts.Layout;
	import talon.utils.Gauge;
	import talon.utils.ParseUtil;

	/** starling.display.TextField which implements ITalonDisplayObject. */
	public class TalonTextField extends TextField implements ITalonDisplayObject
	{
		// There are 2px padding & 1px flash.text.TextField bug with autoSize disharmony
		private static const TRUE_TYPE_CORRECTION:int = 4 + 1;

		private static var sRect:Rectangle = new Rectangle();
		private static var sPoint:Point = new Point();

		private var _node:Node;
		private var _bridge:TalonDisplayObjectBridge;
		private var _requiresRecompositionWithPadding:Boolean;
		
		private var _cacheWidth:Number;
		private var _cacheHeight:Number;
		
		/** @private */
		public function TalonTextField()
		{
			super(0, 0, null);

			_node = new Node([Attribute.TEXT, Attribute.INTERLINE]);
			_node.getOrCreateAttribute(Attribute.WRAP).inited = "true"; // FIXME: Bad Ya?
			_node.addListener(Event.RESIZE, onNodeResize);
			_node.addListener(Event.ADDED, onNodeParentChange);
			_node.addListener(Event.REMOVED, onNodeParentChange);
			_node.width.auto = measureWidth;
			_node.height.auto = measureHeight;

			// Bridge
			_bridge = new TalonDisplayObjectBridge(this, node);
			_bridge.setAttributeChangeListener(Attribute.TEXT, onTextChange);
			_bridge.setAttributeChangeListener(Attribute.WRAP, onWrapChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_AUTO_SCALE, onAutoScaleChange);
			_bridge.setAttributeChangeListener(Attribute.HALIGN, onHAlignChange, true);
			_bridge.setAttributeChangeListener(Attribute.VALIGN, onVAlignChange, true);
			_bridge.setAttributeChangeListener(Attribute.FONT_NAME, onFontNameChange, true);
			_bridge.setAttributeChangeListener(Attribute.INTERLINE, onInterlineChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_COLOR, onFontColorChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_SIZE, onFontSizeChange);

			batchable = true; // TODO: Allow setup batchable flag
		}

		//
		// Measure size
		//
		private function measureWidth(availableHeight:Number):Number { return _cacheWidth = measure(Infinity, availableHeight).width; }
		private function measureHeight(availableWidth:Number):Number { return _cacheHeight = measure(availableWidth, Infinity).height; }
		private function measure(availableWidth:Number, availableHeight:Number):Rectangle
		{
//			if (_cacheWidth == _cacheWidth && _cacheHeight == _cacheHeight)
//			{
//				sRect.setTo(0, 0, x, y);
//				return sRect;
//			}
			
			var trueTypeCorrection:int = getCompositor(format.font) ? 0 : TRUE_TYPE_CORRECTION;

			var paddingTop:Number = node.paddingTop.toPixels(node.metrics);
			var paddingRight:Number = node.paddingRight.toPixels(node.metrics);
			var paddingBottom:Number = node.paddingBottom.toPixels(node.metrics);
			var paddingLeft:Number = node.paddingLeft.toPixels(node.metrics);

			super.autoSize = getAutoSize(availableWidth == Infinity, availableHeight == Infinity);
			super.width = availableWidth - paddingLeft - paddingRight + trueTypeCorrection;
			super.height = availableHeight - paddingTop - paddingBottom + trueTypeCorrection;
			super.getBounds(this, sRect);				// call super.recompose();
			getTrueTextBounds(sRect);					// calculate true text bounds (which respect font lineHeight)
			super.autoSize = TextFieldAutoSize.NONE;	// restore super.autoSize value

			sRect.width  += paddingLeft + paddingRight;
			sRect.height += paddingTop + paddingBottom;

			// BitmapFont#arrangeChars has floating point error:
			// If TextField used some combination of font, size and text
			// containerWidth & containerHeight have small delta.
			// Ceiling used for compensate those errors
			sRect.width  = Math.ceil(sRect.width);
			sRect.height = Math.ceil(sRect.height);
			
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
						var quadHeight:Number = mesh.getVertexPosition(charQuadIndex*4 + 3, sPoint).y
											  - mesh.getVertexPosition(charQuadIndex*4 + 0, sPoint).y;

						scale = quadHeight / char.height;
					}

					var charLeft:Number = mesh.getVertexPosition(charQuadIndex*4 + 0, sPoint).x - char.xOffset*scale;
					if (charLeft < leftmostCharLeft || leftmostCharLeft != leftmostCharLeft)
						leftmostCharLeft = charLeft;

					var charRight:Number = mesh.getVertexPosition(charQuadIndex*4 + 1, sPoint).x;
					if (charRight > rightmostCharRight || rightmostCharRight != rightmostCharRight)
						rightmostCharRight = charRight;

					var charTop:Number = sPoint.y - char.yOffset*scale;
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
			return out;
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
			// TODO: Make pivot/position in bridge?
			pivotX = node.pivotX.toPixels(node.metrics, node.bounds.width);
			pivotY = node.pivotY.toPixels(node.metrics, node.bounds.height);

			x = node.bounds.x + pivotX;
			y = node.bounds.y + pivotY;

			width = node.bounds.width;
			height = node.bounds.height;
			
			recomposeWithPadding();
		}

		private function onNodeParentChange():void
		{
			var unit:String = _node.fontSize.unit;
			if (unit == Gauge.EM || unit == Gauge.PERCENT || node.getOrCreateAttribute(Attribute.FONT_SIZE).isInherit)
				onFontSizeChange();
		}
		
		//
		// TalonDisplayObjectBridge customization
		//
		/** @private */
		public override function setRequiresRecomposition():void
		{
			_cacheWidth = NaN;
			_cacheHeight = NaN;
			_requiresRecompositionWithPadding = true;
			super.setRequiresRecomposition();
		}

		private function recomposeWithPadding():void
		{
			if (_requiresRecompositionWithPadding)
			{
				// Crop padding from result size
				var trueTypeCorrection:int = getCompositor(format.font) ? 0 : TRUE_TYPE_CORRECTION;

				var paddingTop:Number = node.paddingTop.toPixels(node.metrics);
				var paddingRight:Number = node.paddingRight.toPixels(node.metrics);
				var paddingBottom:Number = node.paddingBottom.toPixels(node.metrics);
				var paddingLeft:Number = node.paddingLeft.toPixels(node.metrics);

				width = _node.bounds.width - paddingLeft - paddingRight + trueTypeCorrection;
				height = _node.bounds.height - paddingTop - paddingBottom + trueTypeCorrection;

				// Call super.recompose();
				super.getBounds(this, sRect);

				// Add padding to mesh
				getTrueTextBounds(sRect);
				var halign:Number = ParseUtil.parseAlign(format.horizontalAlign);
				var valign:Number = ParseUtil.parseAlign(format.verticalAlign);
				var mesh:DisplayObject = getChildAt(0);

				mesh.x = Layout.pad(_node.bounds.width, sRect.width, paddingLeft, paddingRight, halign) - sRect.x;
				mesh.y = Layout.pad(_node.bounds.height, sRect.height, paddingTop, paddingBottom, valign) - sRect.y;

				_requiresRecompositionWithPadding = false;
			}
		}

		/** @private */
		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(recomposeAndRender, painter);
		}

		private function recomposeAndRender(painter:Painter):void
		{
			recomposeWithPadding();

			// In this call recompose() nether will be invoked (already invoked)
			// and now this is analog of super.super.render() :-)
			super.render(painter);
		}

		/** @private */
		public override function hitTest(localPoint:Point):DisplayObject
		{
			return _bridge.hitTestCustom(localPoint);
		}

		/** @private */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(null, targetSpace, resultRect);
		}

		/** @private */
		public override function get textBounds():Rectangle
		{
			recomposeWithPadding();
			return getTrueTextBounds();
		}

		/** @private */
		public override function dispose():void
		{
			_bridge.dispose();
			super.dispose();
		}

		//
		// Properties Delegating
		//

		private function onFontColorChange():void { format.color = ParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }
		private function onFontSizeChange():void { format.size = node.metrics.ppem }
		private function onFontNameChange():void { format.font = node.getAttributeCache(Attribute.FONT_NAME); }
		private function onHAlignChange():void { format.horizontalAlign = _node.getAttributeCache(Attribute.HALIGN) }
		private function onVAlignChange():void { format.verticalAlign = _node.getAttributeCache(Attribute.VALIGN) }
		private function onAutoScaleChange():void { super.autoScale = ParseUtil.parseBoolean(_node.getAttributeCache(Attribute.FONT_AUTO_SCALE)); }
		private function onWrapChange():void { super.wordWrap = ParseUtil.parseBoolean(_node.getAttributeCache(Attribute.WRAP)); }
		private function onInterlineChange():void { format.leading = Gauge.toPixels(_node.getAttributeCache(Attribute.INTERLINE), _node.metrics); }
		private function onTextChange():void { super.text = _node.getAttributeCache(Attribute.TEXT); }

		//
		// ITalonDisplayObject
		//
		public function query(selector:String = null):TalonQuery { return new TalonQuery(this).select(selector); }

		public function get node():Node { return _node; }
		
		//
		// Properties override
		//
		
		/** @private */ public override function set wordWrap(value:Boolean):void {  node.setAttribute(Attribute.WRAP, value.toString()); }
		/** @private */ public override function set text(value:String):void { node.setAttribute(Attribute.TEXT, value) }
		/** @private */ public override function set autoScale(value:Boolean):void { node.setAttribute(Attribute.FONT_AUTO_SCALE, value.toString()); }

		/** @private */ public override function get autoSize():String { return getAutoSize(node.width.isNone, node.height.isNone); }
		/** @private */ public override function set autoSize(value:String):void { trace("[TalonTextFiled]", "Ignore autoSize value, this value defined via node width/height == 'none'"); }

		/** @private */ public override function get border():Boolean { return false; }
		/** @private */ public override function set border(value:Boolean):void { trace("[TalonTextFiled]", "Ignore border value, for debug draw use custom 'fill' property"); }
	}
}
