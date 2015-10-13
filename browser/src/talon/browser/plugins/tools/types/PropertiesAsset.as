package talon.browser.plugins.tools.types
{
	import talon.utils.StringUtil;

	public class PropertiesAsset extends Asset
	{
		private var _properties:Object;

		override protected function initialize():void
		{
			var string:String = readFileStringOrReport();
			if (string == null) return;

			_properties = StringUtil.parseProperties(string);

			for (var propertyName:String in _properties)
				document.factory.addResource(propertyName, _properties[propertyName]);
		}

		override protected function dispose():void
		{
            if (_properties)
                for (var propertyName:String in _properties)
                    document.factory.removeResource(propertyName);

            _properties = null;
		}
	}
}