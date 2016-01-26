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
	import starling.filters.BlurFilter;
	import starling.filters.ColorMatrixFilter;
	import starling.filters.FragmentFilter;
	import starling.filters.FragmentFilterMode;
	import starling.rendering.Painter;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.MatrixUtil;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.GaugeQuad;
	import talon.utils.StringParseUtil;

	/** Provide method for synchronize starling display tree and talon tree. */
	public class DisplayObjectBridge
	{
		//
		// Starling FragmentFilter factories
		//
		private static const _filterParsers:Object = new Object();

		public static function registerFilterParser(name:String, parser:Function):void
		{
			_filterParsers[name] = parser;
		}

		registerFilterParser("brightness", function (prev:FragmentFilter, args:Array):FragmentFilter
		{
			var brightness:Number =  parseNumber(args[0], 0);

			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
			colorMatrixFilter.reset();
			colorMatrixFilter.adjustBrightness(brightness);

			return colorMatrixFilter;
		});

		registerFilterParser("contrast", function (prev:FragmentFilter, args:Array):FragmentFilter
		{
			var contrast:Number = parseNumber(args[0], 0);

			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
			colorMatrixFilter.reset();
			colorMatrixFilter.adjustContrast(contrast);

			return colorMatrixFilter;
		});

		registerFilterParser("hue", function (prev:FragmentFilter, args:Array):FragmentFilter
		{
			var hue:Number = parseNumber(args[0], 0);

			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
			colorMatrixFilter.reset();
			colorMatrixFilter.adjustHue(hue);

			return colorMatrixFilter;
		});

		registerFilterParser("saturation", function (prev:FragmentFilter, args:Array):FragmentFilter
		{
			var saturation:Number = parseNumber(args[0], 0);

			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
			colorMatrixFilter.reset();
			colorMatrixFilter.adjustSaturation(saturation);

			return colorMatrixFilter;
		});

		registerFilterParser("tint", function (prev:FragmentFilter, args:Array):FragmentFilter
		{
			var color:Number = StringParseUtil.parseColor(args[0], Color.WHITE);
			var amount:Number = parseNumber(args[1], 1);

			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
			colorMatrixFilter.reset();
			colorMatrixFilter.tint(color, amount);

			return colorMatrixFilter;
		});

		registerFilterParser("blur", function (prev:FragmentFilter, args:Array):FragmentFilter
		{
			var blurX:Number = parseNumber(args[0], 0);
			var blurY:Number = (args.length > 1 ? parseFloat(args[1]) : blurX) || 0;

			var blurFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
			blurFilter.blurX = blurX;
			blurFilter.blurY = blurY;

			return blurFilter;
		});

		registerFilterParser("drop-shadow", function(prev:FragmentFilter, args:Array):FragmentFilter
		{
			var distance:Number = parseNumber(args[0], 0);
			var angle:Number    = StringParseUtil.parseAngle(args[1], 0.785);
			var color:Number    = StringParseUtil.parseColor(args[2], 0x000000);
			var alpha:Number    = parseNumber(args[3], 0.5);
			var blur:Number     = parseNumber(args[4], 1.0);

			var dropShadowFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
			dropShadowFilter.blurX = dropShadowFilter.blurY = blur;
			dropShadowFilter.offsetX = Math.cos(angle) * distance;
			dropShadowFilter.offsetY = Math.sin(angle) * distance;
			dropShadowFilter.mode = FragmentFilterMode.BELOW;
			dropShadowFilter.setUniformColor(true, color, alpha);

			return dropShadowFilter;
		});

		registerFilterParser("glow", function(prev:FragmentFilter, args:Array):FragmentFilter
		{
			var color:Number    = StringParseUtil.parseColor(args[0], 0xffffff);
			var alpha:Number    = parseNumber(args[1], 0.5);
			var blur:Number     = parseNumber(args[2], 1.0);

			var glowFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
			glowFilter.blurX = glowFilter.blurY = blur;
			glowFilter.mode = FragmentFilterMode.BELOW;
			glowFilter.setUniformColor(true, color, alpha);

			return glowFilter;
		});

		private static function getCleanBlurFilter(result:BlurFilter):BlurFilter
		{
			result ||= new BlurFilter();
			result.blurX = result.blurY = 0;
			result.offsetX = result.offsetY = 0;
			result.mode = FragmentFilterMode.REPLACE;
			result.setUniformColor(false);
			return result;
		}

		private static function parseNumber(value:*, ifNaN:Number):Number
		{
			var result:Number = parseFloat(value);
			if (result != result) result = ifNaN;
			return result;
		}

		//
		// Bridge
		//
		private const MATRIX:Matrix = new Matrix();
		private const POINT:Point = new Point();
		private const GRID:GaugeQuad = new GaugeQuad();

		private var _target:DisplayObject;
		private var _node:Node;
		private var _background:FillModeMesh;

		public function DisplayObjectBridge(target:DisplayObject, node:Node):void
		{
			_target = target;
			_target.addEventListener(TouchEvent.TOUCH, onTouchForInteractionPurpose);
			_target.addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);

			_node = node;
			_node.addTriggerListener(Event.RESIZE, onNodeResize);

			_background = new FillModeMesh();

			// Background
			addAttributeChangeListener(Attribute.BACKGROUND_9SCALE,     onBackground9ScaleChange);
			addAttributeChangeListener(Attribute.BACKGROUND_COLOR,      onBackgroundColorChange);
			addAttributeChangeListener(Attribute.BACKGROUND_FILL_MODE,  onBackgroundFillModeChange);
			addAttributeChangeListener(Attribute.BACKGROUND_IMAGE,      onBackgroundImageChange);
//			addAttributeChangeListener(Attribute.BACKGROUND_TINT,       onBackgroundTintChange);
			addAttributeChangeListener(Attribute.BACKGROUND_ALPHA,      onBackgroundAlphaChange);
			addAttributeChangeListener(Attribute.BACKGROUND_BLEND_MODE, onBackgroundBlendModeChange);

			// Common options
			addAttributeChangeListener(Attribute.ID,                    onIDChange);
			addAttributeChangeListener(Attribute.VISIBLE,               onVisibleChange);
			addAttributeChangeListener(Attribute.FILTER,                onFilterChange);
			addAttributeChangeListener(Attribute.ALPHA,                 onAlphaChange);
			addAttributeChangeListener(Attribute.CURSOR,                onCursorChange);
			addAttributeChangeListener(Attribute.BLEND_MODE,            onBlendModeChange);
		}

		public function addAttributeChangeListener(attribute:String, listener:Function):void
		{
			_node.getOrCreateAttribute(attribute).change.addListener(listener);
		}

		private function onNodeResize():void
		{
			_background.width = _node.bounds.width;
			_background.height = _node.bounds.height;
		}

		//
		// Listeners: Background
		//
		private function onBackgroundImageChange():void { _background.texture = _node.getAttributeCache(Attribute.BACKGROUND_IMAGE) as Texture; }
//		private function onBackgroundTintChange():void { _background.tint = StringParseUtil.parseColor(_node.getAttributeCache(Attribute.BACKGROUND_COLOR), Color.WHITE); }
		private function onBackgroundFillModeChange():void { _background.horizontalFillMode = _background.verticalFillMode = _node.getAttributeCache(Attribute.BACKGROUND_FILL_MODE); }
		private function onBackgroundBlendModeChange():void { _background.blendMode = _node.getAttributeCache(Attribute.BACKGROUND_BLEND_MODE); }
		private function onBackgroundAlphaChange():void { _background.alpha = parseFloat(_node.getAttributeCache(Attribute.BACKGROUND_ALPHA)); }

		private function onBackgroundColorChange():void
		{
			var value:String = _node.getAttributeCache(Attribute.BACKGROUND_COLOR);
			_background.transparent = value == Attribute.NONE;
			_background.color = StringParseUtil.parseColor(value, Color.WHITE);
		}

		private function onBackground9ScaleChange():void
		{
			var textureWidth:int = _background.texture ? _background.texture.width : 0;
			var textureHeight:int = _background.texture ? _background.texture.height : 0;

			var backgroundScale9Grid:String = _node.getAttributeCache(Attribute.BACKGROUND_9SCALE);
			GRID.parse(backgroundScale9Grid);

			_background.setStretchOffsets
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
		private function onVisibleChange():void { _target.visible = StringParseUtil.parseBoolean(_node.getAttributeCache(Attribute.VISIBLE)); }
		private function onAlphaChange():void { _target.alpha = parseFloat(_node.getAttributeCache(Attribute.ALPHA)); }
		private function onBlendModeChange():void { _target.blendMode = _node.getAttributeCache(Attribute.BLEND_MODE); }

		private function onFilterChange():void
		{
			var prevFilter:FragmentFilter = _target.filter;
			var nextFilter:FragmentFilter = null;

			var func:String = _node.getAttributeCache(Attribute.FILTER);
			var funcSplit:Array = StringParseUtil.parseFunction(func);
			if (funcSplit)
			{
				var funcName:String = funcSplit.shift();
				var filterParser:Function = _filterParsers[funcName];
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

			_node.states.lock();

			if (touch == null)
			{
				_node.states.remove("hover");
				_node.states.remove("active");
			}
			else if (touch.phase == TouchPhase.HOVER)
			{
				_node.states.insert("hover");
			}
			else if (touch.phase == TouchPhase.BEGAN && !_node.states.contains("active"))
			{
				_node.states.insert("active");
			}
			else if (touch.phase == TouchPhase.MOVED)
			{
				var isWithinBounds:Boolean = _target.getBounds(_target.stage).contains(touch.globalX, touch.globalY);

				if (_node.states.contains("active") && !isWithinBounds)
				{
					_node.states.remove("hover");
					_node.states.remove("active");
				}
				else if (!_node.states.contains("active") && isWithinBounds)
				{
					_node.states.insert("hover");
					_node.states.insert("active");
				}
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				_node.states.remove("hover");
				_node.states.remove("active");
			}

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
			// FIXME: Вынести пересчёт построчно
			if (_node.isInvalidated && (_node.parent == null || !_node.parent.isInvalidated))
			{
				_node.commit();
			}
		}

		//
		// Public methods witch must be used in target DisplayObject
		//
		public function renderBackground(painter:Painter):void
		{
			if (_background.visible)
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
			if (_background.texture/* || !_background.transparent*/)
			{
				_target.getTransformationMatrix(targetSpace, MATRIX);

				var topLeft:Point = MatrixUtil.transformCoords(MATRIX, 0, 0, POINT);
				if (resultRect.left > topLeft.x) resultRect.left = topLeft.x;
				if (resultRect.top > topLeft.y) resultRect.top = topLeft.y;

				var bottomRight:Point = MatrixUtil.transformCoords(MATRIX, _background.width, _background.height, POINT);
				if (resultRect.right < bottomRight.x) resultRect.right = bottomRight.x;
				if (resultRect.bottom < bottomRight.y) resultRect.bottom = bottomRight.y;
			}

			return resultRect;
		}
	}
}