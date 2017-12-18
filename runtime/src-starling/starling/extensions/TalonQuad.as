package starling.extensions
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.rendering.Painter;
	import starling.textures.Texture;
	import starling.utils.Pool;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.core.Style;
	import talon.utils.ParseUtil;

	/** starling.display.Quad which implements ITalonDisplayObject. */
	public class TalonQuad extends Quad implements ITalonDisplayObject
	{
		private static var _sRectangle:Rectangle = new Rectangle();

		private var _bridge:TalonDisplayObjectBridge;
		private var _vertexOffset:Point;

		/** @private */
		public function TalonQuad()
		{
			_vertexOffset = new Point();

			super(1, 1);

			_bridge = new TalonDisplayObjectBridge(this);
			_bridge.setAttributeChangeListener(Attribute.SOURCE, onSourceChange);
			_bridge.setAttributeChangeListener(Attribute.TINT, onSourceTintChange);

			node.width.auto = measureWidth;
			node.height.auto = measureHeight;
			node.addListener(Event.RESIZE, onNodeResize);
			
			_vertexOffset = new Point();

			pixelSnapping = true;
		}

		private function measureWidth(height:Number):Number
		{
			// If there is no texture - size is 100px, like default starling Image
			return (texture ? measure(height, texture.height, texture.width) : 100)
				 + node.paddingLeft.toPixels()
				 + node.paddingRight.toPixels();
		}

		private function measureHeight(width:Number):Number
		{
			return (texture ? measure(width,  texture.width,  texture.height) : 100)
				 + node.paddingTop.toPixels()
				 + node.paddingBottom.toPixels();
		}

		private function measure(knownDimension:Number, knownDimensionOfTexture:Number, measuredDimensionOfTexture:Number):Number
		{
			if (texture == null) throw new Error();
			// If no limit on image size - return original texture size
			if (knownDimension == Infinity) return measuredDimensionOfTexture;
			// Else calculate new size preserving texture aspect ratio
			return measuredDimensionOfTexture * (knownDimension/knownDimensionOfTexture);
		}

		private function onSourceChange():void
		{
			texture = node.getAttributeCache(Attribute.SOURCE) as Texture;
			node.invalidateLayout();
		}

		private function onSourceTintChange():void
		{
			color = ParseUtil.parseColor(node.getAttributeCache(Attribute.TINT));
		}

		private function onNodeResize():void
		{
			var paddingLeft:Number = node.paddingLeft.toPixels();
			var paddingRight:Number = node.paddingRight.toPixels();
			var paddingTop:Number = node.paddingTop.toPixels();
			var paddingBottom:Number = node.paddingBottom.toPixels();

			_vertexOffset.setTo(paddingLeft, paddingTop);

			readjustSize(node.bounds.width-paddingLeft-paddingRight, node.bounds.height-paddingTop-paddingBottom);
		}
		
		/** @private */
		protected override function setupVertices():void
		{
			super.setupVertices();

			// Offset vertices by padding

			if (_vertexOffset.x != 0 || _vertexOffset.y != 0)
			{
				var posAttr:String = "position";
				var point:Point = Pool.getPoint();

				for (var i:int = 0; i < vertexData.numVertices; i++)
				{
					point = vertexData.getPoint(i, posAttr, point);
					point.offset(_vertexOffset.x, _vertexOffset.y);
					vertexData.setPoint(i, posAttr, point.x, point.y);
				}

				Pool.putPoint(point);
			}
		}

		/** @private */
		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(super.render, painter);
		}

		/** @private */
		public override function getBounds(targetSpace:DisplayObject, out:Rectangle = null):Rectangle
		{
			return _bridge.getBoundsCustom(super.getBounds, targetSpace, out);
		}

		/** @private */
		public override function hitTest(localPoint:Point):DisplayObject
		{
			if (!visible || !touchable) return null;
			if (mask && !hitTestMask(localPoint)) return null;
			return getBounds(this, _sRectangle).containsPoint(localPoint) ? this : null;
		}

		/** @private */
		public override function dispose():void
		{
			_bridge.dispose();
			super.dispose();
		}

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
	}
}
