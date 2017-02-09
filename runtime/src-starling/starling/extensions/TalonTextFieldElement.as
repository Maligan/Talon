package starling.extensions
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.MeshBatch;
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
		private static var _helperRect:Rectangle = new Rectangle();

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
			var result:Rectangle = super.getBounds(this, _helperRect); // Call super.recompose()
			super.autoSize = TextFieldAutoSize.NONE;

			fixWidth(result);
			fixHeight(result);

			// Add padding
			result.width  += node.paddingLeft.toPixels(node) + node.paddingRight.toPixels(node);
			result.height += node.paddingTop.toPixels(node)  + node.paddingBottom.toPixels(node);

			return result;
		}

		private function fixWidth(result:Rectangle):void
		{
			var bitmapFont:BitmapFont = getCompositor(format.font) as BitmapFont;
			if (bitmapFont)
			{
				var mesh:MeshBatch = getChildAt(0) as MeshBatch;

				var left:int = int.MAX_VALUE;
				var leftmostCharIndex:int = 0;

				var right:int = int.MIN_VALUE;
				var rightmostCharIndex:int = 0;
				var numWhitespaces:int = 0;
				var numUnrenderables:int = 0;

				for (var i:int = 0; i < text.length; i++)
				{
					var charCode:int = text.charCodeAt(i);
					if (charIsWhitespace(charCode))
						numWhitespaces++;
					else if (bitmapFont.getChar(charCode) == null)
						numUnrenderables++;
					else
					{
						var quadIndex:int = i-numWhitespaces-numUnrenderables;
						var quadRight:int = mesh.getVertexPosition((quadIndex+1)*4-1).x;
						if (quadRight > right)
						{
							rightmostCharIndex = i;
							right = quadRight;
						}

						var quadLeft:int = mesh.getVertexPosition((quadIndex+1)*4-1-3).x;
						if (quadLeft < left)
						{
							leftmostCharIndex = i;
							left = quadLeft;
						}
					}
				}

				if (right != 0)
					result.width = right - left;
			}
		}

		private function fixHeight(result:Rectangle):void
		{
			var bitmapFont:BitmapFont = getCompositor(format.font) as BitmapFont;
			if (bitmapFont)
			{
				var mesh:MeshBatch = getChildAt(0) as MeshBatch;
				var meshBounds:Rectangle = mesh.getBounds(mesh);

				// Get last rendered char
				var lastCharYOffset:int = 0;
				var lastCharIndex:int = text.length;
				while (--lastCharIndex > -1)
				{
					var charCode:int = text.charCodeAt(lastCharIndex);
					var char:BitmapChar = bitmapFont.getChar(charCode);
					if (char && !charIsWhitespace(charCode))
					{
						lastCharYOffset = Math.max(0, -char.yOffset);
						break;
					}
				}

				// Whitespaces does not create quad in mesh - calculate quad index in MeshBatch for last char
				var numWhitespaces:int = 0;
				var numUnrenderables:int = 0;
				for (var i:int = 0; i < lastCharIndex; i++)
				{
					charCode = text.charCodeAt(i);
					if (charIsWhitespace(charCode))
						numWhitespaces++;
					else if (bitmapFont.getChar(charCode)==null)
						numUnrenderables++;
				}

				var quadIndex:int = lastCharIndex - numWhitespaces - numUnrenderables;

				// Calculate numLines and fix total height of text field
				if (quadIndex > -1)
				{
					var scale:Number = format.size / bitmapFont.size;
					var lastCharQuadY:int = mesh.getVertexPosition((quadIndex+1)*4-1 - 3).y + lastCharYOffset*scale;
					var lineOffset:Number = bitmapFont.lineHeight*scale + format.leading;
					var numLines:int = 1 + int(lastCharQuadY/lineOffset);
					result.height = numLines*bitmapFont.lineHeight*scale + (numLines - 1)*format.leading;
//					trace(text.charAt(lastCharIndex) + "(" + lastCharYOffset + ")", numLines, result.height)
				}
			}
		}

		private function charIsWhitespace(charCode:int):Boolean
		{
			// Only char codes from BitmapFont class
			return (charCode == 32 || charCode == 9 || charCode == 10 || charCode == 13);
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
				super.getBounds(this, _helperRect);

				var meshBatch:DisplayObject = getChildAt(0);
				var meshBounds:Rectangle = meshBatch.getBounds(meshBatch, _helperRect);

				// Add horizontal padding
				var halign:Number = ParseUtil.parseAlign(format.horizontalAlign);
				var paddingLeft:Number = node.paddingLeft.toPixels(node);
				var paddingRight:Number = node.paddingRight.toPixels(node);
				meshBatch.x = Layout.pad(_node.bounds.width, meshBounds.width, paddingLeft, paddingRight, halign) - meshBounds.x;

				// Add vertical padding
				var valign:Number = ParseUtil.parseAlign(format.verticalAlign);
				var paddingTop:Number = node.paddingTop.toPixels(node);
				var paddingBottom:Number = node.paddingBottom.toPixels(node);
				meshBatch.y += Layout.pad(_node.bounds.height, meshBounds.height, paddingTop, paddingBottom, valign) - meshBounds.y;

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
			return getBounds(this, _helperRect).containsPoint(localPoint) ? this : null;
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
