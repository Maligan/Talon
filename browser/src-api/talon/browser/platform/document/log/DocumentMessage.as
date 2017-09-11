package talon.browser.platform.document.log
{
	import starling.utils.StringUtil;

	public class DocumentMessage
	{
		//
		// Types
		//
		public static const FILE_READ_ERROR:String =                    "E1:    {0}: Reading throw {1}";
		public static const FILE_LISTING_ERROR:String =                 "E2:    {0}: Listing throw {1}";

		public static const FILE_CONTAINS_WRONG_CSS:String =            "E3:    {0}: Wrong CSS";
		public static const FILE_CONTAINS_WRONG_XML:String =            "E4:    {0}: Wrong XML";
		public static const FILE_CONTAINS_WRONG_ELEMENT:String =        "E5:    {0}: Wrong element: {1}";
		public static const FILE_CONTAINS_WRONG_TEMPLATE:String =       "E6:    {0}: Wrong template: {1}";
		public static const FILE_CONTAINS_WRONG_IMAGE_FORMAT:String =   "E7:    {0}: Loading as bitmap throw: {1}";

		public static const TEXTURE_ERROR:String =                      "E8:    {0}: Uploading to texture throw {1}";
		public static const TEXTURE_MISS_ATLAS:String =                 "W9:    Texture '{1}' for atlas '{0}' not found";
		public static const TEXTURE_MISS_FONT:String =                  "W10:   Texture '{1}' for font '{0}' not found";

		public static const TEMPLATE_INSTANTIATE_ERROR:String =         "E11:   Template '{0}' instantiate throw: {1}";
		public static const TEMPLATE_RESOURCE_MISS:String =				"W12:	Template '{0}' resource '{1}' not found";
		
		public static const RESOURCE_CONFLICT:String =					"E13:	Resource '{0}' already exist";

		//
		// Message
		//
		private var _number:int;
		private var _level:int;
		private var _text:String;

		public function DocumentMessage(type:String, args:Array)
		{
			var pattern:RegExp = /(E|W|I)(\d+):\s*(.+)/;
			var split:Array = pattern.exec(type);
			if (split == null) throw new ArgumentError("Type is invalid");

			_level = (split[1]=="E") ? 2 : (split[1]=="W") ? 1 : 0;
			_number = parseInt(split[2]);

			args.unshift(split[3]);
			_text = StringUtil.format.apply(this, args);
		}

		public function get number():int { return _number }
		public function get level():int { return _level }
		public function get text():String { return _text }
	}
}
