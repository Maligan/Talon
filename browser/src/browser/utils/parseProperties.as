package browser.utils
{
	public function parseProperties(string:String):Object
	{
		var properties:Object = {};
		var key:String = null;
		var value:String = null;
		var mode:int = MODE_IDLE;

		var cursor:int = 0;
		var cursorCharCode:int = 0;
		var cursorEscaped:Boolean = false;

		var buffer:Array = ARRAY;
		var bufferLength:int = 0;

		var stringLength:int = string.length;

		while (cursor < stringLength)
		{
			cursorCharCode = string.charCodeAt(cursor);

			switch (mode)
			{
				case MODE_IDLE:

					switch (cursorCharCode)
					{
						// Begin of comment
						case HASH: case EXCLAMATION:
							mode = MODE_COMMENT;
							cursor++; //@
							break;

						// Ignore whitespaces
						case NEWLINE: case RETURN: case TAB: case SPACE:
							cursor++;
							break;

						// Begin of token
						default:
							mode = MODE_KEY;
							break;
					}

					break;

				case MODE_COMMENT:

					switch (cursorCharCode)
					{
						// End of comment
						case NEWLINE: case RETURN:
							mode = MODE_IDLE;
							cursor++; //@
							break;

						// Commented character
						default:
							cursor++;
							break;
					}

					break;

				case MODE_KEY:

					switch (cursorCharCode)
					{
						// Separator between key and value
						case TAB: case SPACE: case COLON: case EQUALS:

//							key = String.fromCharCode.apply(null, buffer);
							buffer.length = 0;
							bufferLength = 0;

							mode = MODE_EQUALS;
							cursor++; //@
							break;

						default:
							buffer[bufferLength++] = cursorCharCode;
							cursor++;
							break;
					}

					break;

				case MODE_EQUALS:

					switch (cursorCharCode)
					{
						// Trim whitespaces after key
						case TAB: case SPACE:
							cursor++;
							break;

						case EQUALS: case COLON:
							cursor++;
							mode = MODE_VALUE;
							break;

						// End of equals
						default:
							mode = MODE_VALUE;
							break;
					}

					break;

				case MODE_VALUE:

					switch (cursorCharCode)
					{
						case SPACE: case TAB:

							if (bufferLength == 0)
							{
								cursor++;
							}
							else
							{
								buffer[bufferLength++] = cursorCharCode;
								cursor++;
							}

							break;

						case NEWLINE: case RETURN:

//							value = String.fromCharCode.apply(null, buffer);
							buffer.length = 0;
							bufferLength = 0;

							properties[key] = value;
							key = null;
							value = null;

							mode = MODE_IDLE;
							cursor++; //@
							break;

						default:
							buffer[bufferLength++] = cursorCharCode;
							cursor++;
							break;

					}

					break;
			}
		}

		return properties;
	}
}

const ARRAY:Array       = [];

const MODE_IDLE:int     = 0;
const MODE_COMMENT:int  = 1;
const MODE_KEY:int      = 2;
const MODE_EQUALS:int   = 3;
const MODE_VALUE:int    = 4;

const NEWLINE:int       = "\n".charCodeAt(0);
const RETURN:int        = "\r".charCodeAt(0);
const TAB:int           = "\t".charCodeAt(0);
const BACKSLASH:int     = "\\".charCodeAt(0);
const SPACE:int         = " ".charCodeAt(0);
const EXCLAMATION:int   = "!".charCodeAt(0);
const HASH:int          = "#".charCodeAt(0);
const COLON:int         = ":".charCodeAt(0);
const EQUALS:int        = "=".charCodeAt(0);