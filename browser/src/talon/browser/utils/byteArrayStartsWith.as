package talon.browser.utils
{
	import flash.utils.ByteArray;

	/** NB! Clone of staling.utils.AssetManager#byteArrayStartsWith(). */
	public function byteArrayStartsWith(bytes:ByteArray, char:String):Boolean
	{
		var start:int = 0;
		var length:int = bytes.length;
		var wanted:int = char.charCodeAt(0);

		// recognize BOMs

		if (length >= 4 &&
			(bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xfe && bytes[3] == 0xff) ||
			(bytes[0] == 0xff && bytes[1] == 0xfe && bytes[2] == 0x00 && bytes[3] == 0x00))
		{
			start = 4; // UTF-32
		}
		else if (length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf)
		{
			start = 3; // UTF-8
		}
		else if (length >= 2 && (bytes[0] == 0xfe && bytes[1] == 0xff) || (bytes[0] == 0xff && bytes[1] == 0xfe))
			{
				start = 2; // UTF-16
			}

		// find first meaningful letter

		for (var i:int=start; i<length; ++i)
		{
			var byte:int = bytes[i];
			if (byte == 0 || byte == 10 || byte == 13 || byte == 32) continue; // null, \n, \r, space
			else return byte == wanted;
		}

		return false;
	}
}
