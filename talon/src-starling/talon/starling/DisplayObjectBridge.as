package talon.starling
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.events.EnterFrameEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.FragmentFilter;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.MatrixUtil;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.GaugeQuad;
	import talon.utils.StringUtil;

	/** Provide method for synchronize starling display tree and talon tree. */
	internal class DisplayObjectBridge
	{
		private const MATRIX:Matrix = new Matrix();
		private const POINT:Point = new Point();
		private const GRID:GaugeQuad = new GaugeQuad();
		private const RECTANGLE:Rectangle = new Rectangle();

		private var _target:DisplayObject;
		private var _node:Node;
		private var _filler:BackgroundRenderer;

		public function DisplayObjectBridge(target:DisplayObject, node:Node):void
		{
			_target = target;
			_target.addEventListener(TouchEvent.TOUCH, onTouchForInteractionPurpose);
			_target.addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);

			_node = node;
			_filler = new BackgroundRenderer();

			_node.states.change.addListener(function():void
			{
				if (_node.getAttributeCache("type") == "topcoat")
					trace(_node.states);
			});

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
			addAttributeChangeListener(Attribute.ALPHA,                 onAlphaChange);
			addAttributeChangeListener(Attribute.CURSOR,                onCursorChange);
		}

		public function addAttributeChangeListener(attribute:String, listener:Function):void
		{
			_node.getOrCreateAttribute(attribute).change.addListener(listener);
		}

		//
		// Listeners: Background
		//
		private function onBackgroundImageChange():void { _filler.texture = _node.getAttributeCache(Attribute.BACKGROUND_IMAGE) as Texture; }
		private function onBackgroundTintChange():void { _filler.tint = StringUtil.parseColor(_node.getAttributeCache(Attribute.BACKGROUND_COLOR), Color.WHITE); }
		private function onBackgroundFillModeChange():void { _filler.fillMode = _node.getAttributeCache(Attribute.BACKGROUND_FILL_MODE); }

		private function onBackgroundColorChange():void
		{
			var value:String = _node.getAttributeCache(Attribute.BACKGROUND_COLOR);
			_filler.transparent = value == Attribute.TRANSPARENT;
			_filler.color = StringUtil.parseColor(value, _filler.color);
		}

		private function onBackground9ScaleChange():void
		{
			var textureWidth:int = _filler.texture ? _filler.texture.width : 0;
			var textureHeight:int = _filler.texture ? _filler.texture.height : 0;

			var backgroundScale9Grid:String = _node.getAttributeCache(Attribute.BACKGROUND_9SCALE);
			GRID.parse(backgroundScale9Grid);

			_filler.setScaleOffsets
			(
				GRID.top.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				GRID.right.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureWidth),
				GRID.bottom.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				GRID.left.toPixels(_node.ppmm, _node.ppem, _node.ppdp, textureWidth)
			);
		}

		//
		// Listeners: Common
		//
		private function onIDChange():void { _target.name = _node.getAttributeCache(Attribute.ID); }
		private function onVisibilityChange():void { _target.visible = StringUtil.parseBoolean(_node.getAttributeCache(Attribute.VISIBILITY)); }
		private function onAlphaChange():void { _target.alpha = parseFloat(_node.getAttributeCache(Attribute.ALPHA)); }

		private function onFilterChange():void
		{
			_target.filter && _target.filter.dispose();
			_target.filter = _node.getAttributeCache(Attribute.FILTER) as FragmentFilter;
		}

		private function onCursorChange():void
		{
			var cursor:String = _node.getAttributeCache(Attribute.CURSOR);
			if (cursor == MouseCursor.AUTO) _target.removeEventListener(TouchEvent.TOUCH, onTouchForCursorPurpose);
			else _target.addEventListener(TouchEvent.TOUCH, onTouchForCursorPurpose);
		}

		private function onTouchForCursorPurpose(e:TouchEvent):void
		{
			Mouse.cursor = e.interactsWith(_target)
				? _node.getAttributeCache(Attribute.CURSOR)
				: MouseCursor.AUTO;
		}

		//
		// Interaction
		//
		private function onTouchForInteractionPurpose(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(_target);

			_node.states.lock();

			var isHover:Boolean = touch && touch.phase == TouchPhase.HOVER;
			isHover ? _node.states.add("hover") : _node.states.remove("hover");

			var isActive:Boolean = touch && touch.phase == TouchPhase.BEGAN;
			isActive ? _node.states.add("active") : _node.states.remove("active");


			_node.states.unlock();
		}

		//
		// Invalidation
		//
		// Validation subsystem based on render methods/rules/context etc.
		// thus why I do not include invalidation/validation in Talon core
		//
		public function onEnterFrame(e:EnterFrameEvent):void
		{
			if (_node.isInvalidated && (_node.parent == null || !_node.parent.isInvalidated))
			{
				_node.validate();
			}
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