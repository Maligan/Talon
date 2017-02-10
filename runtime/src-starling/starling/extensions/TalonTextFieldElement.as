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

	import talon.Attribute;
	import talon.Node;
	import talon.layouts.Layout;
	import talon.utils.ParseUtil;

	public class TalonTextFieldElement extends TextField implements ITalonElement
	{
		private static var _sRect:Rectangle = new Rectangle();
		private static var _sPoint:Point = new Point();

		private var _node:Node;
		private var _bridge:TalonDisplayObjectBridge;
		private var _requiresRecomposition:Boolean;

		public function TalonTextFieldElement()
		{
			super(0, 0, null);

			_node = new Node();
			_node.getOrCreateAttribute(Attribute.WRAP).inited = "true";
			_node.addTriggerListener(Event.RESIZE, onNodeResize);
			_node.width.auto = measureWidth;
			_node.height.auto = measureHeight;

			// Bridge
			_bridge = new TalonDisplayObjectBridge(this, node);
			_bridge.addAttributeChangeListener(Attribute.TEXT, onTextChange);
			_bridge.addAttributeChangeListener(Attribute.WRAP, onWrapChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_AUTO_SCALE, onAutoScaleChange);
			_bridge.addAttributeChangeListener(Attribute.HALIGN, onHAlignChange, true);
			_bridge.addAttributeChangeListener(Attribute.VALIGN, onVAlignChange, true);
			_bridge.addAttributeChangeListener(Attribute.FONT_NAME, onFontNameChange, true);
			_bridge.addAttributeChangeListener(Attribute.FONT_COLOR, onFontColorChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_SIZE, onFontSizeChange);

			batchable = true; // TODO: Allow setup batchable flag
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
			super.getBounds(this, _sRect);	// call super.recompose();
			getTrueTextBounds(_sRect);		// calculate true text bounds (which respect font lineHeight)
			super.autoSize = TextFieldAutoSize.NONE;

			_sRect.width  += node.paddingLeft.toPixels(node) + node.paddingRight.toPixels(node);
			_sRect.height += node.paddingTop.toPixels(node)  + node.paddingBottom.toPixels(node);

			return _sRect;
		}

		private function getTrueTextBounds(out:Rectangle = null):Rectangle
		{
			out ||= new Rectangle();
			out.setEmpty();

			var mesh:Mesh = getChildAt(0) as Mesh;
			var font:BitmapFont = getCompositor(format.font) as BitmapFont;
			if (font == null) return mesh.getBounds(this, out);

			var scale:Number = format.size / font.size;
			var numDrawableChars:int = mesh.numVertices / 4;
			if (numDrawableChars == 0)
			{
				out.width  = 0;
				out.height = font.lineHeight * scale;
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

				var charIsDrawable:Boolean = char && charID != 32 && charID != 9 && charID != 10 && charID != 13;
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

			var numLines:int = 1 + int((bottommostCharTop - topmostCharTop)/ (font.lineHeight*scale + format.leading));
			var width:Number = rightmostCharRight - leftmostCharLeft;
			var height:Number = numLines*font.lineHeight*scale + (numLines-1)*format.leading;

			out.setTo(0, 0, width, height);
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
			pivotX = node.pivotX.toPixels(node, node.bounds.width);
			pivotY = node.pivotY.toPixels(node, node.bounds.height);

			x = node.bounds.x + pivotX;
			y = node.bounds.y + pivotY;

			width = node.bounds.width;
			height = node.bounds.height;
		}

		//
		// TalonDisplayObjectBridge customization
		//
		protected override function setRequiresRecomposition():void
		{
			_requiresRecomposition = true;
			super.setRequiresRecomposition();
		}

		private function recomposeWithPadding():void
		{
			if (_requiresRecomposition)
			{
				super.setRequiresRecomposition();
				super.getBounds(this, _sRect);

				var meshBatch:DisplayObject = getChildAt(0);
				var meshBounds:Rectangle = meshBatch.getBounds(meshBatch, _sRect);

				// Add horizontal padding
				var halign:Number = ParseUtil.parseAlign(format.horizontalAlign);
				var paddingLeft:Number = node.paddingLeft.toPixels(node);
				var paddingRight:Number = node.paddingRight.toPixels(node);
				meshBatch.x = Layout.pad(_node.bounds.width, meshBounds.width, paddingLeft, paddingRight, halign) - meshBounds.x;

				// Add vertical padding
				var valign:Number = ParseUtil.parseAlign(format.verticalAlign);
				var paddingTop:Number = node.paddingTop.toPixels(node);
				var paddingBottom:Number = node.paddingBottom.toPixels(node);
				meshBatch.y = Layout.pad(0, 0, paddingTop, paddingBottom, valign);

				_requiresRecomposition = false;
			}
		}

		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(recomposeAndRender, painter);
		}

		private function recomposeAndRender(painter:Painter):void
		{
			if (_requiresRecomposition) recomposeWithPadding();

			// In this call recompose() nether will be invoked (already invoked)
			// and now this is analog of super.super.render() :-)
			super.render(painter);
		}

		public override function hitTest(localPoint:Point):DisplayObject
		{
			return getBounds(this, _sRect).containsPoint(localPoint) ? this : null;
		}

		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(null, targetSpace, resultRect);
		}

		public override function dispose():void
		{
			_bridge.dispose();
			super.dispose();
		}

		//
		// Properties Delegating
		//

		private function onFontColorChange():void { format.color = ParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }
		private function onFontSizeChange():void { format.size = node.ppem }
		private function onFontNameChange():void { format.font = node.getAttributeCache(Attribute.FONT_NAME); }
		private function onHAlignChange():void { format.horizontalAlign = _node.getAttributeCache(Attribute.HALIGN) }
		private function onVAlignChange():void { format.verticalAlign = _node.getAttributeCache(Attribute.VALIGN) }
		private function onAutoScaleChange():void { super.autoScale = ParseUtil.parseBoolean(_node.getAttributeCache(Attribute.FONT_AUTO_SCALE)); }
		private function onWrapChange():void { super.wordWrap = ParseUtil.parseBoolean(_node.getAttributeCache(Attribute.WRAP)); }
		private function onTextChange():void
		{
			super.text = _node.getAttributeCache(Attribute.TEXT);

			if (autoSize != TextFieldAutoSize.NONE)
				node.invalidate();
		}

		//
		// Properties
		//
		public function get node():Node { return _node; }


		override public function set wordWrap(value:Boolean):void {  node.setAttribute(Attribute.WRAP, value.toString()); }
		public override function set text(value:String):void { node.setAttribute(Attribute.TEXT, value) }
		public override function set autoScale(value:Boolean):void { node.setAttribute(Attribute.FONT_AUTO_SCALE, value.toString()); }

		public override function get autoSize():String { return getAutoSize(node.width.isNone, node.height.isNone); }
		public override function set autoSize(value:String):void { trace("[TalonTextFiled]", "Ignore autoSize value, this value defined via node width/height == 'none'"); }

		public override function get border():Boolean { return false; }
		public override function set border(value:Boolean):void { trace("[TalonTextFiled]", "Ignore border value, for debug draw use custom 'fill' property"); }
	}
}
