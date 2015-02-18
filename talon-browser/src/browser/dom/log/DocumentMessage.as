package browser.dom.log
{
	import browser.utils.Constants;

	import starling.utils.formatString;

	public class DocumentMessage
	{
		//
		// Types
		//
		// Errors
		public static const FILE_READ_ERROR:String =                "E1:    Can't access to file {0}";
		public static const FILE_XML_PARSE_ERROR:String =           "E2:    File {0} is not valid XML";
		public static const FILE_CSS_PARSE_ERROR:String =           "E3:    File {0} is not valid CSS";
		public static const FILE_TEXTURE_FORMAT_UNKNOWN:String =    "E4:    File {0} has unknown texture format (supported only " + Constants.SUPPORTED_IMAGE_EXTENSIONS.join() + " formats)";
		public static const GPU_TEXTURE_LIMIT_REACHED:String =      "E5:    Texture limit overhead (used {0}mb GPU memory)";
		public static const TALON_RESOURCE_ALREADY_EXISTS:String =  "E6:    Resource with id = {0} already exists";
		public static const TALON_RESOURCE_NOT_FOUND:String =       "W7:    Resource with id = {0} can't be found";

		//
		// Message
		//
		private var _number:int;
		private var _level:int;
		private var _text:String;

		public function DocumentMessage(type:String, ...args)
		{
			var pattern:RegExp = /(E|W|I)(\d+):\s*(.+)/;
			var split:Array = pattern.exec(type);
			if (split == null) throw new ArgumentError("Type is invalid");

			_level = (split[1]=="E") ? 2 : (split[1]=="W") ? 1 : 0;
			_number = parseInt(split[2]);
			_text = formatString.apply(split[3], args);
		}

		public function get number():int { return _number }
		public function get level():int { return _level }
		public function get text():String { return _text }
	}
}