package talon.starling
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	import starling.display.DisplayObject;
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
	import talon.utils.Gauge;
	import talon.utils.StringParseUtil;

	/** Provide method for synchronize starling display tree and talon tree. */
	public class DisplayObjectBridge
	{
		private const MATRIX:Matrix = new Matrix();
		private const POINT:Point = new Point();

		private var _target:DisplayObject;
		private var _node:Node;
		private var _background:FillableMesh;

		public function DisplayObjectBridge(target:DisplayObject, node:Node):void
		{
			_target = target;
			_target.addEventListener(TouchEvent.TOUCH, onTouchForInteractionPurpose);
			_target.addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);

			_node = node;
			_node.addTriggerListener(Event.RESIZE, onNodeResize);

			_background = new FillableMesh();
			_background.pixelSnapping = true;
			_background.addEventListener(Event.CHANGE, _target.setRequiresRedraw);

			// Background
			addAttributeChangeListener(Attribute.BACKGROUND_FILL,           onBackgroundFillChange);
			addAttributeChangeListener(Attribute.BACKGROUND_FILL_MODE,      onBackgroundFillModeChange);
			addAttributeChangeListener(Attribute.BACKGROUND_STRETCH_GRID,   onBackgroundStretchGridChange);
			addAttributeChangeListener(Attribute.BACKGROUND_ALPHA,          onBackgroundAlphaChange);

			// Common options
			addAttributeChangeListener(Attribute.ID,                        onIDChange);
			addAttributeChangeListener(Attribute.VISIBLE,                   onVisibleChange);
			addAttributeChangeListener(Attribute.FILTER,                    onFilterChange);
			addAttributeChangeListener(Attribute.ALPHA,                     onAlphaChange);
			addAttributeChangeListener(Attribute.CURSOR,                    onCursorChange);
			addAttributeChangeListener(Attribute.BLEND_MODE,                onBlendModeChange);
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
		// Listeners: Background
		//
		private function onBackgroundFillChange():void
		{
			var value:* = _node.getAttributeCache(Attribute.BACKGROUND_FILL);
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

		private function onBackgroundFillModeChange():void
		{
			_background.horizontalFillMode = _node.getAttributeCache(Attribute.BACKGROUND_FILL_MODE_HORIZONTAL);
			_background.verticalFillMode = _node.getAttributeCache(Attribute.BACKGROUND_FILL_MODE_VERTICAL);
		}

		private function onBackgroundAlphaChange():void
		{
			_background.alpha = parseFloat(_node.getAttributeCache(Attribute.BACKGROUND_ALPHA));
		}

		private function onBackgroundStretchGridChange():void
		{
			var textureWidth:int = _background.texture ? _background.texture.width : 0;
			var textureHeight:int = _background.texture ? _background.texture.height : 0;

			_background.setStretchOffsets
			(
				Gauge.toPixels(_node.getAttributeCache(Attribute.BACKGROUND_STRETCH_GRID_TOP), _node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				Gauge.toPixels(_node.getAttributeCache(Attribute.BACKGROUND_STRETCH_GRID_RIGHT), _node.ppmm, _node.ppem, _node.ppdp, textureWidth),
				Gauge.toPixels(_node.getAttributeCache(Attribute.BACKGROUND_STRETCH_GRID_BOTTOM), _node.ppmm, _node.ppem, _node.ppdp, textureHeight),
				Gauge.toPixels(_node.getAttributeCache(Attribute.BACKGROUND_STRETCH_GRID_LEFT), _node.ppmm, _node.ppem, _node.ppdp, textureWidth)
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
			resultRect = base(targetSpace, resultRect);

			// Expand resultRect with background bounds
			_target.getTransformationMatrix(targetSpace, MATRIX);

			var topLeft:Point = MatrixUtil.transformCoords(MATRIX, 0, 0, POINT);
			if (resultRect.left > topLeft.x) resultRect.left = topLeft.x;
			if (resultRect.top > topLeft.y) resultRect.top = topLeft.y;

			var bottomRight:Point = MatrixUtil.transformCoords(MATRIX, _background.width, _background.height, POINT);
			if (resultRect.right < bottomRight.x) resultRect.right = bottomRight.x;
			if (resultRect.bottom < bottomRight.y) resultRect.bottom = bottomRight.y;

			return resultRect;
		}
	}
}

//
// Starling FragmentFilter factories
//
//private static const _filterParsers:Object = new Object();
//
//public static function registerFilterParser(name:String, parser:Function):void
//{
//	_filterParsers[name] = parser;
//}
//
//registerFilterParser("brightness", function (prev:FragmentFilter, args:Array):FragmentFilter
//{
//	var brightness:Number =  parseNumber(args[0], 0);
//
//	var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//	colorMatrixFilter.reset();
//	colorMatrixFilter.adjustBrightness(brightness);
//
//	return colorMatrixFilter;
//});
//
//registerFilterParser("contrast", function (prev:FragmentFilter, args:Array):FragmentFilter
//{
//	var contrast:Number = parseNumber(args[0], 0);
//
//	var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//	colorMatrixFilter.reset();
//	colorMatrixFilter.adjustContrast(contrast);
//
//	return colorMatrixFilter;
//});
//
//registerFilterParser("hue", function (prev:FragmentFilter, args:Array):FragmentFilter
//{
//	var hue:Number = parseNumber(args[0], 0);
//
//	var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//	colorMatrixFilter.reset();
//	colorMatrixFilter.adjustHue(hue);
//
//	return colorMatrixFilter;
//});
//
//registerFilterParser("saturation", function (prev:FragmentFilter, args:Array):FragmentFilter
//{
//	var saturation:Number = parseNumber(args[0], 0);
//
//	var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//	colorMatrixFilter.reset();
//	colorMatrixFilter.adjustSaturation(saturation);
//
//	return colorMatrixFilter;
//});
//
//registerFilterParser("tint", function (prev:FragmentFilter, args:Array):FragmentFilter
//{
//	var color:Number = StringParseUtil.parseColor(args[0], Color.WHITE);
//	var amount:Number = parseNumber(args[1], 1);
//
//	var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//	colorMatrixFilter.reset();
//	colorMatrixFilter.tint(color, amount);
//
//	return colorMatrixFilter;
//});
//
//registerFilterParser("blur", function (prev:FragmentFilter, args:Array):FragmentFilter
//{
//	var blurX:Number = parseNumber(args[0], 0);
//	var blurY:Number = (args.length > 1 ? parseFloat(args[1]) : blurX) || 0;
//
//	var blurFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
//	blurFilter.blurX = blurX;
//	blurFilter.blurY = blurY;
//
//	return blurFilter;
//});
//
//registerFilterParser("drop-shadow", function(prev:FragmentFilter, args:Array):FragmentFilter
//{
//	var distance:Number = parseNumber(args[0], 0);
//	var angle:Number    = StringParseUtil.parseAngle(args[1], 0.785);
//	var color:Number    = StringParseUtil.parseColor(args[2], 0x000000);
//	var alpha:Number    = parseNumber(args[3], 0.5);
//	var blur:Number     = parseNumber(args[4], 1.0);
//
//	var dropShadowFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
//	dropShadowFilter.blurX = dropShadowFilter.blurY = blur;
//	dropShadowFilter.offsetX = Math.cos(angle) * distance;
//	dropShadowFilter.offsetY = Math.sin(angle) * distance;
//	dropShadowFilter.mode = FragmentFilterMode.BELOW;
//	dropShadowFilter.setUniformColor(true, color, alpha);
//
//	return dropShadowFilter;
//});
//
//registerFilterParser("glow", function(prev:FragmentFilter, args:Array):FragmentFilter
//{
//	var color:Number    = StringParseUtil.parseColor(args[0], 0xffffff);
//	var alpha:Number    = parseNumber(args[1], 0.5);
//	var blur:Number     = parseNumber(args[2], 1.0);
//
//	var glowFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
//	glowFilter.blurX = glowFilter.blurY = blur;
//	glowFilter.mode = FragmentFilterMode.BELOW;
//	glowFilter.setUniformColor(true, color, alpha);
//
//	return glowFilter;
//});
//
//private static function getCleanBlurFilter(result:BlurFilter):BlurFilter
//{
//	result ||= new BlurFilter();
//	result.blurX = result.blurY = 0;
//	result.offsetX = result.offsetY = 0;
//	result.mode = FragmentFilterMode.REPLACE;
//	result.setUniformColor(false);
//	return result;
//}
//
//private static function parseNumber(value:*, ifNaN:Number):Number
//{
//	var result:Number = parseFloat(value);
//	if (result != result) result = ifNaN;
//	return result;
//}