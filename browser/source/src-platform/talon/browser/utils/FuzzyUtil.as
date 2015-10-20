package talon.browser.utils
{
	public class FuzzyUtil
	{
		/** Select all items witch fuzzy match query, and sort by Levenshtein order. */
		public static function fuzzyFilter(query:String, items:Array):Array
		{
			query = query.toLowerCase();

			var result:Array = [];

			for each (var item:String in items)
			{
				var itemLower:String = item.toLowerCase();
				var itemMatch:Boolean = fuzzyMatch(query, itemLower);
				if (itemMatch) result[result.length] = item;
			}

			result.sort();
			return result;
		}


		/** Test item contains all chars from query in same order. */
		public static function fuzzyMatch(query:String, item:String):Boolean
		{
			var split:Array = query.split('');
			var regex:RegExp = new RegExp(split.join(".*?"));
			return regex.test(item);
		}

		/** Test item contains all chars from query in same order. */
		public static function fuzzyHighlight(query:String, item:String, atBegin:String, atEnd:String):String
		{
			if (!query || !item) return item;

			var queryLower:String = query.toLowerCase();
			var itemLower:String = item.toLowerCase();
			if (fuzzyMatch(queryLower, itemLower) == false) return item;

			var result:Array = [];
			var prescription:Array = getPrescription(queryLower, itemLower);
			var highlight:Boolean = false;

			for (var i:int = 0; i < prescription.length; i++)
			{
				var h:Boolean = prescription[i] == "M";
				if (highlight != h)
				{
					result.push(h ? atBegin : atEnd);
					highlight = h;
				}

				result.push(item.charAt(i));
			}

			if (highlight) result.push(atEnd);

			return result.join('');
		}

		public static function getPrescription(str1:String , str2:String):Array
		{
			const OP_DELETE:int   = "D".charCodeAt(0); // Delete
			const OP_INSERT:int   = "I".charCodeAt(0); // Insert
			const OP_REPLACE:int  = "R".charCodeAt(0); // Replace
			const OP_MATCH:int    = "M".charCodeAt(0); // Match

			var m:int = str1.length;
			var n:int = str2.length;

			var D:* = getMatrix(m + 1, n + 1);
			var O:* = getMatrix(m + 1, n + 1);

			// Базовые значения
			for (var i:int = 0; i <= m; i++)
			{
				D[i][0] = i;
				O[i][0] = OP_DELETE;
			}

			for (var j:int = 0; j <= n; j++)
			{
				D[0][j] = j;
				O[0][j] = OP_INSERT;
			}

			// Построение таблицы переходов
			for (i = 1; i <= m; i++)
			for (j = 1; j <= n; j++)
			{
				var cost:int = (str1.charAt(i-1) != str2.charAt(j-1)) ? 1 : 0;

				if (D[i][j-1] < D[i-1][j] && D[i][j-1] < D[i-1][j-1] + cost)
				{
					// Вставка
					D[i][j] = D[i][j-1] + 1;
					O[i][j] = OP_INSERT;
				}
				else if (D[i-1][j] < D[i-1][j-1] + cost)
				{
					// Удаление
					D[i][j] = D[i-1][j] + 1;
					O[i][j] = OP_DELETE;
				}
				else
				{
					// Замена или отсутствие операции
					D[i][j] = D[i-1][j-1] + cost;
					O[i][j] = (cost == 1) ? OP_REPLACE : OP_MATCH;
				}
			}

			// Восстановление предписания
			var route:Array = new Array();
			i = m;
			j = n;

			do
			{
				var op:int = O[i][j];

				route.push(String.fromCharCode(op));

				if (op == OP_REPLACE || op == OP_MATCH)
				{
					i --;
					j --;
				}
				else if (op == OP_DELETE)
				{
					i --;
				}
				else
				{
					j --;
				}
			} while ((i != 0) || (j != 0));


			// Результат
			route.distance = D[m][n];
			route.reverse();
			return route;
		}

		private static function getMatrix(m:int, n:int):Vector.<Vector.<int>>
		{
			var matrix:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(m, true);

			for (var i:int = 0; i < matrix.length; i++)
				matrix[i] = new Vector.<int>(n, true);

			return matrix;
		}
	}
}
