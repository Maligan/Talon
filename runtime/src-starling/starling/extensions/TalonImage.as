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
	import talon.utils.ParseUtil;

	public class TalonImage extends Quad implements ITalonDisplayObject
	{
		private static var _sRectangle:Rectangle = new Rectangle();

		private var _bridge:TalonDisplayObjectBridge;
		private var _node:Node;
		private var _vertexOffset:Point;
		private var _manual:Boolean;

		public function TalonImage()
		{
			_vertexOffset = new Point();

			super(1, 1);

			_node = new Node();
			_node.width.auto = measureWidth;
			_node.height.auto = measureHeight;
			_node.addTriggerListener(Event.RESIZE, onNodeResize);

			_bridge = new TalonDisplayObjectBridge(this, node);
			_bridge.setAttributeChangeListener(Attribute.SOURCE, onSourceChange);
			_bridge.setAttributeChangeListener(Attribute.SOURCE_TINT, onSourceTintChange);

			_vertexOffset = new Point();

			pixelSnapping = true;
		}

		private function measureWidth(height:Number):Number
		{
			// If there is no texture - size is 100px, like default starling Image
			return (texture ? measure(height, texture.height, texture.width) : 100)
				 + node.paddingLeft.toPixels(node.metrics)
				 + node.paddingRight.toPixels(node.metrics);
		}

		private function measureHeight(width:Number):Number
		{
			return (texture ? measure(width,  texture.width,  texture.height) : 100)
				 + node.paddingTop.toPixels(node.metrics)
				 + node.paddingBottom.toPixels(node.metrics);
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
			var prevW:int = texture ? texture.width  : -1;
			var prevH:int = texture ? texture.height : -1;
			texture = node.getAttributeCache(Attribute.SOURCE) as Texture;
			var currW:int = texture ? texture.width  : -1;
			var currH:int = texture ? texture.height : -1;

			if (node.width.isNone && (prevW != currW) || node.height.isNone && (prevH != currH)) node.invalidate();
		}

		private function onSourceTintChange():void
		{
			color = ParseUtil.parseColor(_node.getAttributeCache(Attribute.SOURCE_TINT));
		}

		private function onNodeResize():void
		{
			pivotX = node.pivotX.toPixels(node.metrics, node.bounds.width);
			pivotY = node.pivotY.toPixels(node.metrics, node.bounds.height);

			if (!manual)
			{
				x = node.bounds.x + pivotX;
				y = node.bounds.y + pivotY;
			}

			var paddingLeft:Number = node.paddingLeft.toPixels(node.metrics);
			var paddingRight:Number = node.paddingRight.toPixels(node.metrics);
			var paddingTop:Number = node.paddingTop.toPixels(node.metrics);
			var paddingBottom:Number = node.paddingBottom.toPixels(node.metrics);

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

		public function get node():Node
		{
			return _node;
		}

		public function query(selector:String = null):TalonQuery
		{
			return new TalonQuery(this).select(selector);
		}

		public function get manual():Boolean
		{
			return _manual;
		}

		public function set manual(value:Boolean):void
		{
			_manual = value;
		}
	}
}
