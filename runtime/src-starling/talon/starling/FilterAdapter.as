package talon.starling
{
	import starling.filters.ColorMatrixFilter;
	import starling.filters.FilterChain;
	import starling.filters.FragmentFilter;

	public class FilterAdapter
	{
		private static var _initialized:Boolean;
		private static var _parsers:Object;

		private static function initialize():void
		{
			if (_initialized == false)
			{
				_initialized = true;
				registerFilter("brightness", parserBrightness);
				registerFilter("", null);
				registerFilter("", null);
				registerFilter("", null);
			}
		}

		public static function registerFilter(name:String, parser:Function):void
		{
			initialize();

			_parsers[name] = parser;
		}

		public static function getFilter(name:String):Function
		{
			initialize();

			var parser:Function = _parsers[name];
			if (parser == null)
			{
				parser = parserEmpty;
				trace("[FilterAdapter]", "Parser for '" + name + "' is not registered");
			}

			return parser;
		}

		//
		// Common parsing
		//
		public static function parseFilter(string:String, result:FragmentFilter = null):FragmentFilter
		{
			var sources:Vector.<Array> = decomposeArgs(string);
			var filters:Vector.<FragmentFilter> = decomposeFilters(result);
			var recomposited:Boolean = false;

			for (var i:int = 0; i < sources.length; i++)
			{
				var source:Array = sources[i];
				var filter:FragmentFilter = i<filters.length ? filters[i] : null;

				var filterAfterRefresh:FragmentFilter = refresh(source, filter);
				if (filterAfterRefresh != filter)
				{
					recomposited = true;
					filters[i] = filterAfterRefresh;
					filter.dispose();
				}
			}

			return composeFilters(filters, recomposited, result);
		}

		private static function decomposeArgs(string:String):Vector.<Array>
		{
			return null;
		}

		private static function decomposeFilters(filter:FragmentFilter):Vector.<FragmentFilter>
		{
			var result:Vector.<FragmentFilter> = new Vector.<FragmentFilter>();
			result.length = 0;

			if (filter is FilterChain)
			{
				var chain:FilterChain = FilterChain(filter);
				for (var i:int = 0; i < chain.numFilters; i++)
					result[i] = chain.getFilterAt(i);
			}
			else
				result[0] = filter;

			return result;
		}

		private static function composeFilters(filters:Vector.<FragmentFilter>, recomposited:Boolean, result:FragmentFilter = null):FragmentFilter
		{
			if (filters.length == 1) return filters[0];

			var chain:FilterChain = result as FilterChain || new FilterChain();

			if (recomposited)
			{
				while (chain.numFilters)
					chain.removeFilterAt(0);

				for each (var filter:FragmentFilter in filters)
					chain.addFilter(filter);
			}

			return chain;
		}

		private static function refresh(args:Array, result:FragmentFilter = null):FragmentFilter
		{
			var filterName:String = args.shift();
			var filterParser:Function = getFilter(filterName);
			return filterParser.length == 2
				 ? filterParser(args, result)
				 : filterParser(args);
		}

		//
		// Implementations
		//
		private static function parserEmpty(args:Array, filter:FragmentFilter):FragmentFilter
		{
			return new FragmentFilter();
		}

		private static function parserBrightness(args:Array, prev:FragmentFilter):FragmentFilter
		{
			var brightness:Number = parseNumber(args[0], 0);

			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
			colorMatrixFilter.reset();
			colorMatrixFilter.adjustBrightness(brightness);

			return colorMatrixFilter;
		}
//
//		registerFilterParser("contrast", function (prev:FragmentFilter, args:Array):FragmentFilter
//		{
//			var contrast:Number = parseNumber(args[0], 0);
//
//			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//			colorMatrixFilter.reset();
//			colorMatrixFilter.adjustContrast(contrast);
//
//			return colorMatrixFilter;
//		});
//
//		registerFilterParser("hue", function (prev:FragmentFilter, args:Array):FragmentFilter
//		{
//			var hue:Number = parseNumber(args[0], 0);
//
//			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//			colorMatrixFilter.reset();
//			colorMatrixFilter.adjustHue(hue);
//
//			return colorMatrixFilter;
//		});
//
//		registerFilterParser("saturation", function (prev:FragmentFilter, args:Array):FragmentFilter
//		{
//			var saturation:Number = parseNumber(args[0], 0);
//
//			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//			colorMatrixFilter.reset();
//			colorMatrixFilter.adjustSaturation(saturation);
//
//			return colorMatrixFilter;
//		});
//
//		registerFilterParser("tint", function (prev:FragmentFilter, args:Array):FragmentFilter
//		{
//			var color:Number = StringParseUtil.parseColor(args[0], Color.WHITE);
//			var amount:Number = parseNumber(args[1], 1);
//
//			var colorMatrixFilter:ColorMatrixFilter = prev as ColorMatrixFilter || new ColorMatrixFilter();
//			colorMatrixFilter.reset();
//			colorMatrixFilter.tint(color, amount);
//
//			return colorMatrixFilter;
//		});
//
//		registerFilterParser("blur", function (prev:FragmentFilter, args:Array):FragmentFilter
//		{
//			var blurX:Number = parseNumber(args[0], 0);
//			var blurY:Number = (args.length > 1 ? parseFloat(args[1]) : blurX) || 0;
//
//			var blurFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
//			blurFilter.blurX = blurX;
//			blurFilter.blurY = blurY;
//
//			return blurFilter;
//		});
//
//		registerFilterParser("drop-shadow", function(prev:FragmentFilter, args:Array):FragmentFilter
//		{
//			var distance:Number = parseNumber(args[0], 0);
//			var angle:Number    = StringParseUtil.parseAngle(args[1], 0.785);
//			var color:Number    = StringParseUtil.parseColor(args[2], 0x000000);
//			var alpha:Number    = parseNumber(args[3], 0.5);
//			var blur:Number     = parseNumber(args[4], 1.0);
//
//			var dropShadowFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
//			dropShadowFilter.blurX = dropShadowFilter.blurY = blur;
//			dropShadowFilter.offsetX = Math.cos(angle) * distance;
//			dropShadowFilter.offsetY = Math.sin(angle) * distance;
//			dropShadowFilter.mode = FragmentFilterMode.BELOW;
//			dropShadowFilter.setUniformColor(true, color, alpha);
//
//			return dropShadowFilter;
//		});
//
//		registerFilterParser("glow", function(prev:FragmentFilter, args:Array):FragmentFilter
//		{
//			var color:Number    = StringParseUtil.parseColor(args[0], 0xffffff);
//			var alpha:Number    = parseNumber(args[1], 0.5);
//			var blur:Number     = parseNumber(args[2], 1.0);
//
//			var glowFilter:BlurFilter = getCleanBlurFilter(prev as BlurFilter);
//			glowFilter.blurX = glowFilter.blurY = blur;
//			glowFilter.mode = FragmentFilterMode.BELOW;
//			glowFilter.setUniformColor(true, color, alpha);
//
//			return glowFilter;
//		});
//
//		private static function getCleanBlurFilter(result:BlurFilter):BlurFilter
//		{
//			result ||= new BlurFilter();
//			result.blurX = result.blurY = 0;
//			result.offsetX = result.offsetY = 0;
//			result.mode = FragmentFilterMode.REPLACE;
//			result.setUniformColor(false);
//			return result;
//		}

		private static function parseNumber(value:*, ifNaN:Number):Number
		{
			var result:Number = parseFloat(value);
			if (result != result) result = ifNaN;
			return result;
		}
	}
}
