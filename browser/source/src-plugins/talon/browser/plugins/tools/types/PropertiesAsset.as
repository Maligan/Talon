package talon.browser.plugins.tools.types
{
	import talon.utils.StringParseUtil;

	public class PropertiesAsset extends Asset
	{
		private var _properties:Object;

		override protected function activate():void
		{
			var string:String = readFileStringOrReport();
			if (string == null) return;

			_properties = StringParseUtil.parseProperties(string);

			for (var propertyName:String in _properties)
				document.factory.addResource(propertyName, _properties[propertyName]);
		}

		override protected function deactivate():void
		{
            if (_properties)
                for (var propertyName:String in _properties)
                    document.factory.removeResource(propertyName);

            _properties = null;
		}
	}
}