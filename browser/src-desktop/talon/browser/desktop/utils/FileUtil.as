package talon.browser.desktop.utils
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class FileUtil
	{
		public static function readText(file:File):String { return readBytes(file).toString(); }

		public static function readBytes(file:File):ByteArray
		{
			var result:ByteArray = new ByteArray();

			try
			{
				var stream:FileStream = new FileStream();
				stream.open(file, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
			}
			finally
			{
				stream.close();
				return result;
			}
		}
	}
}
