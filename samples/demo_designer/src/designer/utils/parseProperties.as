package designer.utils
{
	/** Simple JProperties file format parser. */
	public function parseProperties(string:String):Object
	{
		var result:Object = new Object();
		var values:Array = string.split(/[\n\r]/);
		var pattern:RegExp = /\s*([\w\.]+)\s*\=\s*(.*)\s*$/;

		for each (var line:String in values)
		{
			var property:Array = pattern.exec(line);
			if (property)
			{
				var key:String = property[1];
				var value:String = property[2];
				result[key] = value;
			}
		}

		return result;
	}
}
