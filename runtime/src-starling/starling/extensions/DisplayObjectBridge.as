package starling.extensions
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.DisplayObjectTraitor;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.FragmentFilter;
	import starling.rendering.Painter;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.MatrixUtil;
	import starling.utils.StringUtil;

	import talon.Attribute;
	import talon.Node;
	import talon.enums.TouchMode;
	import talon.utils.Gauge;
	import talon.utils.StringParseUtil;

	/** Provide method for synchronize starling display tree and talon tree. */
	public class DisplayObjectBridge
	{
		private const MATRIX:Matrix = new Matrix();
		private const POINT:Point = new Point();

		private var _target:DisplayObject;
		private var _node:Node;
		private var _background:FillModeMesh;

		public function DisplayObjectBridge(target:DisplayObject, node:Node):void
		{
			_target = target;
			_target.addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);

			_node = node;
			_node.addTriggerListener(Event.RESIZE, onNodeResize);

			_background = new FillModeMesh();
			_background.pixelSnapping = true;
			_background.addEventListener(Event.CHANGE, _target.setRequiresRedraw);

			// Background
			addAttributeChangeListener(Attribute.FILL,           onFillChange);
			addAttributeChangeListener(Attribute.FILL_MODE,      onFillModeChange);
			addAttributeChangeListener(Attribute.FILL_STRETCH_GRID,   onFillStretchGridChange);
			addAttributeChangeListener(Attribute.FILL_ALPHA,          onFillAlphaChange);

			// Common options
			addAttributeChangeListener(Attribute.ID,                        onIDChange);
			addAttributeChangeListener(Attribute.VISIBLE,                   onVisibleChange);
			addAttributeChangeListener(Attribute.FILTER,                    onFilterChange);
			addAttributeChangeListener(Attribute.ALPHA,                     onAlphaChange);
			addAttributeChangeListener(Attribute.BLEND_MODE,                onBlendModeChange);

			// Interactive
			addAttributeChangeListener(Attribute.TOUCH_MODE,                onTouchModeChange);
			addAttributeChangeListener(Attribute.TOUCH_EVENTS,              onTouchEventsChange);
			addAttributeChangeListener(Attribute.CURSOR,                    onCursorChange);

			// Pivot
			addAttributeChangeListener(Attribute.PIVOT_X,					onPivotXChange);
			addAttributeChangeListener(Attribute.PIVOT_Y,					onPivotYChange);
		}

		public function addAttributeChangeListener(attribute:String, listener:Function, immediate:Boolean = false):void
		{
			_node.getOrCreateAttribute(attribute).change.addListener(listener);
			// TODO: Trigger context
			if (immediate) listener();
		}

		private function onNodeResize():void
		{
			_background.width = _node.bounds.width;
			_background.height = _node.bounds.height;
		}

		//
		// Pivot
		//
		private function onPivotXChange():void
		{
			_target.pivotX = _node.accessor.pivotX.toPixels(_node.ppmm, _node.ppem, _node.ppdp, _node.bounds.width);
			trace(_target.pivotX);
		}

		private function onPivotYChange():void
		{
			_target.pivotY = _node.accessor.pivotY.toPixels(_node.ppmm, _node.ppem, _node.ppdp, _node.bounds.height);
			trace(_target.pivotY);
		}

		//
		// Listeners: Background
		//
		private function onFillChange():void
		{
			var value:* = _node.getAttributeCache(Attribute.FILL);
			if (value is Texture)
			{
				_background.texture = value;
				_background.color = Color.WHITE;
				_background.transparent = false;
			}
			else
			{
				_background.texture = null;
				_background.color = StringParseUtil.parseColor(value, Color.WHITE);
				_background.transparent = value == Attribute.NONE;
			}
		}

		private function onFillModeChange():void
		{
			_background.horizontalFillMode = _node.getAttributeCache(Attribute.FILL_MODE_HORIZONTAL);
			_background.verticalFillMode = _node.getAttributeCache(Attribute.FILL_MODE_VERTICAL);
		}

		private function onFillAlphaChange():void
		{
			_background.alpha = parseFloat(_node.getAttributeCache(Attribute.FILL_ALPHA));
		}

		private function onFillStretchGridChange():void
		{
			var textureWidth:int = _background.texture ? _background.texture.width : 0;
			var textureHeight:int = _background.texture ? _background.texture.height : 0;

			_background.setStretchOffsets
			(
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_TOP), _node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_RIGHT), _node.ppmm, _node.ppem, _node.ppdp, textureWidth),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_BOTTOM), _node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_LEFT), _node.ppmm, _node.ppem, _node.ppdp, textureWidth)
			);
		}

		//
		// Listeners: Common
		//
		private function onIDChange():void { _target.name = _node.getAttributeCache(Attribute.ID); }
		private function onVisibleChange():void { _target.visible = StringParseUtil.parseBoolean(_node.getAttributeCache(Attribute.VISIBLE)); }
		private function onAlphaChange():void { _target.alpha = parseFloat(_node.getAttributeCache(Attribute.ALPHA)); }
		private function onBlendModeChange():void { _target.blendMode = _node.getAttributeCache(Attribute.BLEND_MODE); }

		private function onFilterChange():void
		{
			trace("[DisplayObjectBridge]", "Filters are disabled in Starling 2.0");
			return;

			var prevFilter:FragmentFilter = _target.filter;
			var nextFilter:FragmentFilter = null;

			var func:String = _node.getAttributeCache(Attribute.FILTER);
			var funcSplit:Array = StringParseUtil.parseFunction(func);
			if (funcSplit)
			{
				var funcName:String = funcSplit.shift();
				var filterParser:Function = null; // _filterParsers[funcName];
				if (filterParser != null)
					nextFilter = filterParser(prevFilter, funcSplit);
			}

			if (prevFilter && prevFilter != nextFilter)
				prevFilter.dispose();

			_target.filter = nextFilter;
		}

		//
		// Interaction
		//
		private function onCursorChange():void
		{
			var cursor:String = _node.getAttributeCache(Attribute.CURSOR);
			if (cursor == MouseCursor.AUTO) _target.removeEventListener(TouchEvent.TOUCH, onTouch_Cursor);
			else _target.addEventListener(TouchEvent.TOUCH, onTouch_Cursor);
		}

		private function onTouchModeChange():void
		{
			var mode:String = _node.getAttributeCache(Attribute.TOUCH_MODE);

			_target.touchable = mode != TouchMode.NONE;

			var targetAsContainer:DisplayObjectContainer = _target as DisplayObjectContainer;
			if (targetAsContainer)
				targetAsContainer.touchGroup = mode != TouchMode.BRANCH;
		}

		private function onTouchEventsChange():void
		{
			var touchEventsValue:String = _node.getAttributeCache(Attribute.TOUCH_EVENTS);
			var touchEvents:Boolean = StringParseUtil.parseBoolean(touchEventsValue);

			if (touchEvents) _target.addEventListener(TouchEvent.TOUCH, onTouch_States);
			else _target.removeEventListener(TouchEvent.TOUCH, onTouch_States);
		}

		private function onTouch_Cursor(e:TouchEvent):void
		{
			Mouse.cursor = e.interactsWith(_target)
				? _node.getAttributeCache(Attribute.CURSOR)
				: MouseCursor.AUTO;
		}

		private function onTouch_States(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(_target);

			_node.accessor.states.lock();

			if (touch == null)
			{
				_node.accessor.states.remove("hover");
				_node.accessor.states.remove("active");
			}
			else if (touch.phase == TouchPhase.HOVER)
			{
				_node.accessor.states.insert("hover");
			}
			else if (touch.phase == TouchPhase.BEGAN && !_node.accessor.states.contains("active"))
			{
				_node.accessor.states.insert("active");
			}
			else if (touch.phase == TouchPhase.MOVED)
			{
				var isWithinBounds:Boolean = _target.getBounds(_target.stage).contains(touch.globalX, touch.globalY);

				if (_node.accessor.states.contains("active") && !isWithinBounds)
				{
					_node.accessor.states.remove("hover");
					_node.accessor.states.remove("active");
				}
				else if (!_node.accessor.states.contains("active") && isWithinBounds)
				{
					_node.accessor.states.insert("hover");
					_node.accessor.states.insert("active");
				}
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				_node.accessor.states.remove("hover");
				_node.accessor.states.remove("active");
			}

			_node.accessor.states.unlock();
		}

		//
		// Invalidation
		//
		// Validation subsystem based on render methods/rules/context etc.
		// thus why I do not include invalidation/validation in Talon core
		//
		private function onEnterFrame(e:EnterFrameEvent):void
		{
			if (_node.invalidated && (_node.parent == null || !_node.parent.invalidated))
			{
				_node.commit();
			}
		}

		//
		// Public methods which must be used in target DisplayObject
		//
		public function renderBackground(painter:Painter):void
		{
			_background.render(painter);
		}

		public function renderChildrenWithZIndex(painter:Painter):void
		{
			DisplayObjectTraitor;
		}

		public function getBoundsCustom(base:Function, targetSpace:DisplayObject, resultRect:Rectangle):Rectangle
		{
			if (resultRect == null) resultRect = new Rectangle();
			else resultRect.setEmpty();

			if (base != null)
				resultRect = base(targetSpace, resultRect);

			var isEmpty:Boolean = resultRect.isEmpty();

			// Expand resultRect with background bounds
			_target.getTransformationMatrix(targetSpace, MATRIX);

			var topLeft:Point = MatrixUtil.transformCoords(MATRIX, 0, 0, POINT);
			if (isEmpty || resultRect.left>topLeft.x) resultRect.left = topLeft.x;
			if (isEmpty || resultRect.top>topLeft.y) resultRect.top = topLeft.y;

			var bottomRight:Point = MatrixUtil.transformCoords(MATRIX, _node.bounds.width, _node.bounds.height, POINT);
			if (isEmpty || resultRect.right<bottomRight.x) resultRect.right = bottomRight.x;
			if (isEmpty || resultRect.bottom<bottomRight.y) resultRect.bottom = bottomRight.y;

			return resultRect;
		}

		public function get hasOpaqueBackground():Boolean
		{
			return _background.texture || !_background.transparent;
		}
	}
}