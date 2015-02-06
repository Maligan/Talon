package browser.utils
{
	import flash.filesystem.File;

	public function findFiles(root:File, recursive:Boolean = true, includeRoot:Boolean = true):Vector.<File>
	{
		var result:Vector.<File> = new Vector.<File>();

		if (includeRoot) result.push(root);

		if (root.isDirectory)
		{
			var children:Array = root.getDirectoryListing();
			for each (var child:File in children)
			{
				result.push(child);
				if (recursive) result = result.concat(findFiles(child, recursive, false));
			}
		}

		return result;
	}
}
