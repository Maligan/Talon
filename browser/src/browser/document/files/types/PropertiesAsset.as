package browser.document.files.types
{
	import browser.document.files.DocumentFileReference;

	import talon.utils.StringUtil;

	public class PropertiesAsset extends Asset
	{
		public static function checker(file:DocumentFileReference):Boolean
		{
			return file.extension == "properties";
		}

		private var _properties:Object;

		public override function attach():void
		{
			var string:String = readFileStringOrReport();
			if (string == null) return;

			_properties = StringUtil.parseProperties(string);

			for (var propertyName:String in _properties)
				document.factory.addResource(propertyName, _properties[propertyName]);
		}

		public override function detach():void
		{
			reportCleanup();

            if (_properties)
                for (var propertyName:String in _properties)
                    document.factory.removeResource(propertyName);

            _properties = null;
		}
	}
}