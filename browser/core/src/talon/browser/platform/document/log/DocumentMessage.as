package talon.browser.platform.document.log
{
	import starling.utils.StringUtil;

	import talon.browser.platform.AppConstants;

	public class DocumentMessage
	{
		//
		// Types
		//
		public static const FILE_READ_ERROR:String =                    "E1:    File '{0}' reading throw {1}";
		public static const FILE_LISTING_ERROR:String =                 "E2:    Folder '{0}' listing throw {1}";

		public static const FILE_CONTAINS_WRONG_CSS:String =            "E3:    File '{0}' contains wrong CSS";
		public static const FILE_CONTAINS_WRONG_XML:String =            "E4:    File '{0}' contains wrong XML";
		public static const FILE_CONTAINS_WRONG_ELEMENT:String =        "E5:    File '{0}' contains wrong element '{1}'";
		public static const FILE_CONTAINS_WRONG_TEMPLATE:String =       "E6:    File '{0}' contains wrong template {1}";
		public static const FILE_CONTAINS_WRONG_IMAGE_FORMAT:String =   "E7:    File '{0}' loading as bitmap throw {1}";

		public static const TEXTURE_ERROR:String =                      "E8:    File '{0}' uploading to texture throw {1}";
		public static const TEXTURE_MISS_ATLAS:String =                 "W9:    Texture '{1}' for atlas '{0}' not found";
		public static const TEXTURE_MISS_FONT:String =                  "W10:   Texture '{1}' for font '{0}' not found";

		public static const TEMPLATE_INSTANTIATE_ERROR:String =         "E11:   Template '{0}' instantiate throw {1}";

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
			args.unshift(split[3]);

			_level = (split[1]=="E") ? 2 : (split[1]=="W") ? 1 : 0;
			_number = parseInt(split[2]);
			_text = StringUtil.format.apply(this, args);
		}

		public function get number():int { return _number }
		public function get level():int { return _level }
		public function get text():String { return _text }
	}
}
