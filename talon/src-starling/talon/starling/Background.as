package talon.starling
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.MatrixUtil;

	import talon.Attribute;

	import talon.Node;
	import talon.types.GaugeQuad;
	import talon.utils.StringUtil;

	internal class Background
	{
		private var _self:DisplayObject;
		private var _node:Node;
		private var _filler:BackgroundFiller;
		private var _grid:GaugeQuad;

		public function Background(self:DisplayObject, node:Node):void
		{
			_self = self;
			_node = node;
			addAttributeChangeListener(Attribute.BACKGROUND_9SCALE, onBackground9ScaleChange);
			addAttributeChangeListener(Attribute.BACKGROUND_COLOR, onBackgroundColorChange);
			addAttributeChangeListener(Attribute.BACKGROUND_FILL_MODE, onBackgroundFillModeChange);
			addAttributeChangeListener(Attribute.BACKGROUND_IMAGE, onBackgroundImageChange);
			addAttributeChangeListener(Attribute.BACKGROUND_TINT, onBackgroundTintChange);

			_filler = new BackgroundFiller();
			_grid = new GaugeQuad();
		}

		//
		// Attribute listeners
		//
		private function addAttributeChangeListener(attribute:String, listener:Function):void
		{
			_node.getOrCreateAttribute(attribute).addEventListener(Event.CHANGE, listener);
		}

		private function onBackgroundFillModeChange(e:Event):void
		{
			_filler.fillMode = _node.getAttribute(Attribute.BACKGROUND_FILL_MODE);
		}

		private function onBackground9ScaleChange(e:Event):void
		{
			var textureWidth:int = _filler.texture ? _filler.texture.width : 0;
			var textureHeight:int = _filler.texture ? _filler.texture.height : 0;

			_grid.parse(_node.getAttribute(Attribute.BACKGROUND_9SCALE));

			_filler.setScaleOffsets(_grid.top.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureHeight), _grid.right.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureWidth), _grid.bottom.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureHeight), _grid.left.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureWidth));
		}

		private function onBackgroundColorChange(e:Event):void
		{
			var value:String = _node.getAttribute(Attribute.BACKGROUND_COLOR);
			_filler.transparent = value == Attribute.TRANSPARENT;
			_filler.color = StringUtil.parseColor(value, _filler.color);
		}

		private function onBackgroundImageChange(e:Event):void
		{
			_filler.texture = _node.getAttribute(Attribute.BACKGROUND_IMAGE) as Texture;
		}

		private function onBackgroundTintChange(e:Event):void
		{
			_filler.tint = StringUtil.parseColor(_node.getAttribute(Attribute.BACKGROUND_COLOR), Color.WHITE);
		}

		//
		// Public methods
		//
		public function render(support:RenderSupport, parentAlpha:Number):void
		{
			_filler.render(support, parentAlpha);
		}

		public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null, base:Function = null):Rectangle
		{
			resultRect = base(targetSpace, resultRect);

			if (_filler.texture || !_filler.transparent)
			{
				var matrix:Matrix = _self.getTransformationMatrix(targetSpace);
				var helper:Point = MatrixUtil.transformCoords(matrix, _filler.width, _filler.height);
				if (resultRect.right < helper.x)
					resultRect.right = helper.x;
				if (resultRect.bottom < helper.y)
					resultRect.bottom = helper.y;
			}

			return resultRect;
		}

		public function hitTest(localPoint:Point, forTouch:Boolean = false, base:Function = null):DisplayObject
		{
			var localX:int = localPoint.x;
			var localY:int = localPoint.y;
			var result:DisplayObject = base(localPoint, forTouch);
			localPoint.setTo(localX, localY);

			if (result == null)
			{
				// on a touch test, invisible or untouchable objects cause the test to fail
				if (forTouch && (!_self.visible || !_self.touchable)) return null;

				// if we've got a mask and the hit occurs outside, fail
				if (_self.mask && !_self.hitTestMask(localPoint)) return null;

				// otherwise, check bounding box
				var bounds:Rectangle = _self.getBounds(_self /**/);
				if (bounds.containsPoint(localPoint))
					result = _self;
			}

			return result;
		}

		public function resize(width:Number, height:Number):void
		{
			_filler.width = width;
			_filler.height = height;
		}
	}
}