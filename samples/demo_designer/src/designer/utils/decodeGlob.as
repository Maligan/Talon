package designer.utils
{
	/** Convert glob pattern to RegExp. */
	public function decodeGlob(glob:String):RegExp
	{
		return new RegExp(translate_f(glob));
	}
}

//based on fnmatch.py
function escape_f(source:String):String
{
	var escapable = /[.\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;
	var meta =
		{
			'\b': '\\b',
			'\t': '\\t',
			'\n': '\\n',
			'\f': '\\f',
			'\r': '\\r',
			'\.': '\\.',
			'"': '\\"',
			'\\': '\\\\'
		};

	function escapechar(a:*)
	{
		return meta[a] ? meta[a] : '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
	}

	return source.replace(escapable, escapechar);
}

function translate_f(pat:String) {
	//Translate a shell PATTERN to a regular expression.
	//There is no way to quote meta-characters.

	var i:int = 0;
	var j:int = 0;
	var n:int = pat.length || 0;
	var res:String = "";
	var c:String = "";
	var stuff:String = "";

	res = '^';
	while (i < n) {
		c = pat.charAt(i);
		i = i + 1;
		if (c === '*') {
			res = res + '.*';
		} else if (c === '?') {
			res = res + '.';
		} else if (c === '[') {
			j = i;
			if (j < n && pat.charAt(j) === '!') {
				j = j + 1;
			}
			if (j < n && pat.charAt(j) === ']') {
				j = j + 1;
			}
			while (j < n && pat.charAt(j) !== ']') {
				j = j + 1;
			}
			if (j >= n) {
				res = res + '\\[';
			} else {
				stuff = pat.slice(i, j).replace('\\', '\\\\');
				i = j + 1;
				if (stuff[0] === '!') {
					stuff = '^' + stuff.slice(1);
				} else if (stuff[0] === '^') {
					stuff = '\\' + stuff;
				}
				res = res + '[' + stuff + ']';
			}
		} else {
			res = res + escape_f(c);
		}
	}
	return res + '$';
}
