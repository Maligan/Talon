package talon.starling
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.FragmentFilter;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.MatrixUtil;

	import talon.Attribute;
	import talon.Node;
	import talon.enums.Visibility;
	import talon.types.GaugeQuad;
	import talon.utils.StringUtil;

	/** Provide method for synchronize starling.display.DisplayObject and talon.Node. */
	internal class DisplayObjectBridge
	{
		private const MATRIX:Matrix = new Matrix();
		private const POINT:Point = new Point();
		private const GRID:GaugeQuad = new GaugeQuad();
		private const RECTANGLE:Rectangle = new Rectangle();

		private var _target:DisplayObject;
		private var _node:Node;
		private var _filler:BackgroundFiller;

		public function DisplayObjectBridge(target:DisplayObject, node:Node):void
		{
			_target = target;
			_target.addEventListener(TouchEvent.TOUCH, onTouchForInteractionPurpose);

			_node = node;
			_filler = new BackgroundFiller();

			// Background
			addAttributeChangeListener(Attribute.BACKGROUND_9SCALE,     onBackground9ScaleChange);
			addAttributeChangeListener(Attribute.BACKGROUND_COLOR,      onBackgroundColorChange);
			addAttributeChangeListener(Attribute.BACKGROUND_FILL_MODE,  onBackgroundFillModeChange);
			addAttributeChangeListener(Attribute.BACKGROUND_IMAGE,      onBackgroundImageChange);
			addAttributeChangeListener(Attribute.BACKGROUND_TINT,       onBackgroundTintChange);

			// Common options
			addAttributeChangeListener(Attribute.ID,                    onIDChange);
			addAttributeChangeListener(Attribute.VISIBILITY,            onVisibilityChange);
			addAttributeChangeListener(Attribute.FILTER,                onFilterChange);
			addAttributeChangeListener(Attribute.CLIPPING,              trace);
			addAttributeChangeListener(Attribute.ALPHA,                 onAlphaChange);
			addAttributeChangeListener(Attribute.CURSOR,                onCursorChange);
		}

		public function addAttributeChangeListener(attribute:String, listener:Function):void
		{
			_node.getOrCreateAttribute(attribute).addEventListener(Event.CHANGE, listener);
		}

		//
		// Listeners: Background
		//
		private function onBackgroundImageChange(e:Event):void { _filler.texture = _node.getAttribute(Attribute.BACKGROUND_IMAGE) as Texture; }
		private function onBackgroundTintChange(e:Event):void { _filler.tint = StringUtil.parseColor(_node.getAttribute(Attribute.BACKGROUND_COLOR), Color.WHITE); }
		private function onBackgroundFillModeChange(e:Event):void { _filler.fillMode = _node.getAttribute(Attribute.BACKGROUND_FILL_MODE); }

		private function onBackgroundColorChange(e:Event):void
		{
			var value:String = _node.getAttribute(Attribute.BACKGROUND_COLOR);
			_filler.transparent = value == Attribute.TRANSPARENT;
			_filler.color = StringUtil.parseColor(value, _filler.color);
		}

		private function onBackground9ScaleChange(e:Event):void
		{
			var textureWidth:int = _filler.texture ? _filler.texture.width : 0;
			var textureHeight:int = _filler.texture ? _filler.texture.height : 0;

			GRID.parse(_node.getAttribute(Attribute.BACKGROUND_9SCALE));

			_filler.setScaleOffsets(
				GRID.top.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				GRID.right.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureWidth),
				GRID.bottom.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				GRID.left.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureWidth)
			);
		}

		//
		// Listeners: Common
		//
		private function onIDChange(e:Event):void { _target.name = _node.getAttribute(Attribute.ID); }
		private function onFilterChange(e:Event):void { _target.filter = _node.getAttribute(Attribute.FILTER) as FragmentFilter; }
		private function onVisibilityChange(e:Event):void { _target.visible = _node.getAttribute(Attribute.VISIBILITY) == Visibility.VISIBLE; }
		private function onAlphaChange(e:Event):void { _target.alpha = parseFloat(_node.getAttribute(Attribute.ALPHA)); }

		private function onCursorChange(e:Event):void
		{
			var cursor:String = _node.getAttribute(Attribute.CURSOR);
			if (cursor == MouseCursor.AUTO) _target.removeEventListener(TouchEvent.TOUCH, onTouchForCursorPurpose);
			else _target.addEventListener(TouchEvent.TOUCH, onTouchForCursorPurpose);
		}

		private function onTouchForCursorPurpose(e:TouchEvent):void
		{
			Mouse.cursor = e.interactsWith(_target)
				? _node.getAttribute(Attribute.CURSOR)
				: MouseCursor.AUTO;
		}

		//
		// Interaction
		//
		private function onTouchForInteractionPurpose(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(_target);

			if (touch == null)
				_node.states = new <String>[];
			else if (touch.phase == TouchPhase.HOVER)
				_node.states = new <String>["hover"];
			else if (touch.phase == TouchPhase.BEGAN)
				_node.states = new <String>["active"];
			else if (touch.phase == TouchPhase.ENDED)
				_node.states = new <String>[];
		}

		//
		// Public methods witch must be used in target DisplayObject
		//
		public function renderBackground(support:RenderSupport, parentAlpha:Number):void
		{
			_filler.render(support, parentAlpha);
		}

		public function getBoundsCustom(base:Function, targetSpace:DisplayObject, resultRect:Rectangle):Rectangle
		{
			resultRect = base(targetSpace, resultRect);

			if (_filler.texture || !_filler.transparent)
			{
				_target.getTransformationMatrix(targetSpace, MATRIX);

				var topLeft:Point = MatrixUtil.transformCoords(MATRIX, 0, 0, POINT);
				if (resultRect.left > topLeft.x) resultRect.left = topLeft.x;
				if (resultRect.top > topLeft.y) resultRect.top = topLeft.y;

				var bottomRight:Point = MatrixUtil.transformCoords(MATRIX, _filler.width, _filler.height, POINT);
				if (resultRect.right < bottomRight.x) resultRect.right = bottomRight.x;
				if (resultRect.bottom < bottomRight.y) resultRect.bottom = bottomRight.y;
			}

			return resultRect;
		}

		public function hitTestCustom(base:Function, localPoint:Point, forTouch:Boolean):DisplayObject
		{
			var localX:int = localPoint.x;
			var localY:int = localPoint.y;
			var result:DisplayObject = base(localPoint, forTouch);
			localPoint.setTo(localX, localY);

			// NB! copy from DisplayObject#hitTest() method
			if (result == null)
			{
				// on a touch test, invisible or untouchable objects cause the test to fail
				if (forTouch && (!_target.visible || !_target.touchable)) return null;

				// if we've got a mask and the hit occurs outside, fail
				if (_target.mask && !_target.hitTestMask(localPoint)) return null;

				// otherwise, check bounding box
				var bounds:Rectangle = _target.getBounds(_target, RECTANGLE);
				if (bounds.contains(localX, localY))
					result = _target;
			}
			// --------------------------------------------

			return result;
		}

		public function resize(width:Number, height:Number):void
		{
			_filler.width = width;
			_filler.height = height;
		}
	}
}