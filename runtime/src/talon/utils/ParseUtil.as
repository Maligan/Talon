package talon.utils
{
	import avmplus.getQualifiedClassName;

	import flash.utils.Dictionary;

	import talon.core.Node;
	import talon.core.Style;

	/** @private This is utility class for work with strings in different formats and notation. */
	public final class ParseUtil
	{
		private static const _parsers:Dictionary = new Dictionary();

		public static function registerClassParser(type:Class, parser:Function):void
		{
			_parsers[type] = parser;
		}

		public static function parseClass(type:Class, string:String, node:Node = null, out:Object = null):*
		{
			var parser:Function = _parsers[type];
			if (parser != null)
				return parser(string || "", node, out) as type;

			throw new Error("Parser for type " + getQualifiedClassName(type) + " not found");
		}

		private static const _sColors:Object =
		{
			white: 0xffffff,
			silver: 0xc0c0c0,
			gray: 0x808080,
			black: 0x000000,
			red: 0xff0000,
			maroon: 0x800000,
			yellow: 0xffff00,
			olive: 0x808000,
			lime: 0x00ff00,
			green: 0x008000,
			aqua: 0x00ffff,
			teal: 0x008080,
			blue: 0x0000ff,
			navy: 0x000080,
			fuchsia: 0xff00ff,
			purple: 0x800080
		};

		/**
		 * Parse color strings:
		 * white
		 * #FFFFFF
		 * rbg(255, 255, 255)
		 */
		public static function parseColor(string:String, fallback:Number = NaN):Number
		{
			var rgb:Array;

			if (string == null) return fallback;
			if (string.indexOf("#") == 0) return parseInt(string.substr(1), 16);

			string = string.toLowerCase();
			if (_sColors.hasOwnProperty(string)) return _sColors[string];

			var method:Array = parseFunction(string.toLowerCase());
			if (method && method[0]=="rgb" && method.length > 3) return (parseInt(method[1]) << 16) | (parseInt(method[2]) << 8) | parseInt(method[3]);

			return fallback;
		}

		public static function parseAngle(string:String, fallback:Number = NaN):Number
		{
			var pattern:RegExp = /^(-?\d*\.?\d+)(deg|rad|)$/;
			var split:Array = pattern.exec(string);
			if (split == null) return fallback;

			var amount:Number = parseFloat(split[1]);
			var unit:String = split[2];
			switch (unit)
			{
				case "rad":
					return amount;

				case "deg":
				default:
					return amount * Math.PI / 180;
			}
		}

		public static function parseNumber(string:String, fallback:Number = NaN):Number
		{
			var result:Number = parseFloat(string);
			if (result == result) return result;
			return fallback;
		}

		/**
		 * Parse strings like:
		 * url(http://example.com/) to ['url', 'http://example.com/']
		 * rgb(128, 128, 128) to ['rgb', '128', '128', '128']
		 * method(arg1) to ['method', 'arg1']
		 * First item - function name, second and other - arguments
		 * Or return null if input string doesn't match css functional notation.
		 *
		 * The format of functional notation is: 'function('
		 * followed by optional white space
		 * followed by an optional single quote (') or double quote (") character
		 * followed by args divided by (,), followed by an optional single quote (') or double quote (") character
		 * followed by optional white space followed by ')'.
		 * The two quote characters must be the same.
		 */
		public static function parseFunction(string:String):Array
		{
			if (string == null) return null;

			// Optimize negative cases
			var indexOfOpen:int = string.indexOf("(");
			if (indexOfOpen == -1) return null;

			// Regexp parsing
			const notation:RegExp = /([\w\d-$]+)\(\s*(["']?)(.*?)\2+\s*\)/;
			var exec:Array = notation.exec(string);
			if (exec == null) return null;

			// Last regexp group is arguments (split & trim)
			var args:Array = exec[3] ? exec[3].split(/\s*,\s*/) : [];
			// First regexp group is function name
			args.unshift(exec[1]);

			return args;
		}

		public static function parseResource(string:String):String
		{
			if (string == null) return null;
			if (string.charAt(0) != "$") return null;

			// Short notation: $resourceKey
			const notation:RegExp = /\$[\w\d-$]+/;
			if (notation.test(string)) return string.substring(1);

			// Functional notation: $("resourceKey")
			var split:Array = parseFunction(string);
			if (split && split.length > 1) return split[1];

			return null;
		}

		public static function parseAlign(string:String):Number
		{
			switch (string)
			{
				case "left":
				case "top":
					return 0.0;
				case "center":
				case "middle":
					return 0.5;
				case "right":
				case "bottom":
					return 1.0;
				default:
					return 0.0;
			}
		}

		public static function parseBoolean(string:String):Boolean
		{
			// Ha-ha, is this really funny?
			// Sometimes ago I have think use other keyword(s) for true or false, like on/off etc.
			return string == "true";
		}

		//
		// From AS3Commons StringUtils class
		//

		private static var WIN_BREAK:String = String.fromCharCode(13) + String.fromCharCode(10);
		private static var MAC_BREAK:String = String.fromCharCode(13);
		private static var DEFAULT_ESCAPE_MAP:Array = ["\\t", "\t", "\\n", "\n", "\\r", "\r", "\\\"", "\"", "\\\\", "\\", "\\'", "\'", "\\f", "\f", "\\b", "\b", "\\", ""];
		private static var PROPERTIES_ESCAPE_MAP:Array = ["\\t", "\t", "\\n", "\n", "\\r", "\r", "\\\"", "\"", "\\\\", "\\", "\\'", "\'", "\\f", "\f"];

		/**
		 * Parses the given <p>source</p> and creates a <p>Properties</p> instance from it.
		 *
		 * <p>Ported from as2lib</p>
		 *
		 * @param source the source to parse
		 * @param properties the properties instance to populate with the properties of the
		 * given source
		 * @return the properties defined by the given <p>source</p>
		 * @author Martin Heidegger
		 * @author Simon Wacker
		 */
		public static function parseProperties(str:String, properties:Object = null):Object
		{
			properties = properties || {};
			var i:Number;
			var lines:Array = str.split(WIN_BREAK).join("\n").split(MAC_BREAK).join("\n").split("\n");
			var length:Number = lines.length;
			var key:String;
			var value:String;
			var formerKey:String;
			var formerValue:String;
			var useNextLine:Boolean = false;

			for (i = 0; i < length; ++i)
			{
				var line:String = lines[i];
				// Trim the line
				line = trim(line);
				// Ignore Comments
				if (line.indexOf("#") != 0 && line.indexOf("!") != 0 && line.length != 0)
				{
					// Line break processing
					if (useNextLine)
					{
						key = formerKey;
						value = formerValue + line;
						useNextLine = false;
					}
					else
					{
						var sep:Number;
						// Gets the seperationated
						var j:Number;
						var l:Number = line.length;
						for (j = 0; j < l; j++)
						{
							var char:String = line.charAt(j);
							if (char == "'") j++;
							else if (char == ":" || char == "=" || char == "\t") break;
						}
						sep = ((j == l) ? line.length : j);
						key = trim(line.substr(0, sep), false, true);
						value = line.substring(sep + 1);
						formerKey = key;
						formerValue = value;
					}
					// Trim the content
					value = trim(value, true, false);
					// Allow normal lines
					if (value.charAt(value.length - 1) == "\\")
					{
						formerValue = value = value.substr(0, value.length - 1);
						useNextLine = true;
					}
					else
					{
						// Commit Property
						properties[key] = escape(value, PROPERTIES_ESCAPE_MAP, false);
					}
				}
			}

			return properties;
		}

		/**
		 * Replaces keys defined in a keymap.
		 *
		 * <p>This method helps if you need to escape characters in a string. But it
		 * can be basically used for any kind of keys to be replaced.</p>
		 *
		 * <p>To be expected as keymap is a map like:
		 * <code>
		 *   ["keyToReplace1", "replacedTo1", "keyToReplace2", "replacedTo2", ... ]
		 * </code></p>
		 *
		 * @param string String that contains content to be removed.
		 * @param keyMap Map that contains all keys. (DEFAULT_ESCAPE_MAP will be used if no keyMap gets passed.
		 * @param ignoreUnicode Pass "true" to ignore automatic parsing of unicode escaped characters.
		 * @return Escaped string.
		 */
		private static function escape(string:String, keyMap:Array=null, ignoreUnicode:Boolean=true):String {
			if (string == null) {
				return string;
			}
			if (!keyMap) {
				keyMap = DEFAULT_ESCAPE_MAP;
			}
			var i:Number = 0;
			var l:Number = keyMap.length;
			while (i < l) {
				string = string.split(keyMap[i]).join(keyMap[i + 1]);
				i += 2;
			}
			if (!ignoreUnicode) {
				i = 0;
				l = string.length;
				while (i < l) {
					if (string.substring(i, i + 2) == "\\u") {
						string = string.substring(0, i) + String.fromCharCode(parseInt(string.substring(i + 2, i + 6), 16)) + string.substring(i + 6);
					}
					i++;
				}
			}
			return string;
		}

		/**
		 * <p>Removes control characters(char &lt;= 32) from both
		 * ends of this String, handling <code>null</code> by returning
		 * <code>null</code>.</p>
		 *
		 * <p>Trim removes start and end characters &lt;= 32.
		 * To strip whitespace use #strip(String).</p>
		 *
		 * <p>To trim your choice of characters, use the
		 * #strip(String, String) methods.</p>
		 *
		 * <pre>
		 * StringUtils.trim(null)          = null
		 * StringUtils.trim("")            = ""
		 * StringUtils.trim("     ")       = ""
		 * StringUtils.trim("abc")         = "abc"
		 * StringUtils.trim("    abc    ") = "abc"
		 * </pre>
		 *
		 * @param str  the String to be trimmed, may be null
		 * @return the trimmed string, <code>null</code> if null String input
		 */
		private static function trim(str:String, left:Boolean = true, right:Boolean = true):String
		{
			if (!str) return str;

			var result:String = str;
			if (left)  result = result.replace(/^\s*/, '');
			if (right) result = result.replace(/\s*$/, '');

			return result;
		}
		
		//
		// Parse CSS
		//

		//
		// Recursive descent parser (BNF):
		//
		// <css>      ::= { <rule> }
		// <rule>     ::= <selector> {',' <selector>} '{' <style> '}'
		// <selector> ::= 'ident' | .'ident' | #'ident' | <selector> <selector> | 'ident':'ident'
		// <style>    ::= { 'ident' ':' 'ident' ';' }
		//
		public static function parseCSS(string:String):Vector.<Style>
		{
			var styles:Object = new OrderedObject();
			var cursor:Vector.<String> = new <String>[];

			parseCSS(string);
			
			// [Parse]
			
			function parseCSS(input:String):void
			{
				input = uncomment(input);
				input = trim(input);

				while (input.length != 0)
				{
					input = parseRule(input);
					input = trim(input);
				}
			}

			function parseRule(input:String):String
			{
				input = parseSelector(input);
				input = parseStyle(input);
				return input;
			}

			function parseSelector(input:String):String
			{
				var startIndex:int = 0;
				var endIndex:int = input.indexOf('{');

				cursor.length = 0;
				var selectors:Array = input.substr(startIndex, endIndex).split(',');
				for each (var selector:String in selectors)
					cursor[cursor.length] = trim(selector).replace(/\s\+/, ' ');

				return input.substr(endIndex);
			}

			function parseStyle(input:String):String
			{
				var startIndex:int = input.indexOf('{');
				var endIndex:int = input.indexOf('}');
				var style:Array = input.substring(startIndex + 1, endIndex).split(';');

				for each (var property:String in style)
				{
					property = trim(property);

					if (property.length > 0)
					{
						var splitProperty:Array = property.split(':');
						var name:String = trim(splitProperty[0]);
						var value:String = trim(splitProperty[1]);
						addCursorSelectorsProperty(name, value);
					}
				}

				return input.substr(endIndex + 1);
			}

			//
			// [Calls]
			//

			function addCursorSelectorsProperty(name:String, value:String):void
			{
				for each (var selector:String in cursor)
				{
					var style:Style = styles[selector] ||= new Style(selector);
					style.values[name] = value;
				}
			}
			
			//
			// [Result]
			//
			var result:Vector.<Style> = new <Style>[];

			for each (var style:Style in styles)
				result[result.length] = style;
			
			return result;
		}

		/** Remove CSS comments. */
		private static function uncomment(string:String):String
		{
			return string.replace(/\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\//g, '');
		}
	}
}